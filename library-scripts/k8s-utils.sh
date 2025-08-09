#!/usr/bin/env bash
# Syntax: ./k8s-utils.sh [non-root user] [Update rc files flag]

HELM_VERSION=${1:-"3.12.0"}
USERNAME=${2:-"automatic"}
UPDATE_RC=${3:-"true"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

function updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zshrc..."
        echo -e "$1" >> /etc/bash.bashrc
        if [ -f "/etc/zshrc" ]; then
            echo -e "$1" >> /etc/zshrc
        fi
    fi
}

function updatebashrc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc..."
        echo -e "$1" >> /etc/bash.bashrc
    fi
}

function updatezshrc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/zshrc..."
        echo -e "$1" >> /etc/zshrc
    fi
}

# Install kubectl
echo "Installing kubectl..."
curl -sSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl
if [ -f "/etc/zshrc" ]; then
    updatezshrc "source <(kubectl completion zsh)"
else
    updatebashrc "source <(kubectl completion bash)"
fi

# Install helm
echo "Installing helm..."
curl -sSL -o /tmp/helm.tar.gz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
tar -xzf /tmp/helm.tar.gz -C /usr/local/bin --strip-components=1
rm -f /tmp/helm.tar.gz
chmod +x /usr/local/bin/helm

# Install kubecolor
echo "Installing kubecolor..."
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --add-repo https://kubecolor.github.io/packages/rpm/kubecolor.repo
dnf install -y kubecolor
updaterc "alias k='kubecolor'"
updaterc "alias kubectl='kubecolor'"
updaterc "alias oc='env KUBECTL_COMMAND=oc kubecolor'"
if [ -f "/etc/zshrc" ]; then
    updatezshrc "compdef kubecolor=kubectl"
else
    updatebashrc "complete -o default -F __start_kubectl kubecolor"
    updatebashrc "complete -o default -F __start_kubectl k"
fi

echo "Done!"
