#!/usr/bin/env bash
# Syntax: ./go-rhel.sh [non-root user] [Update rc files flag]

USERNAME=${1:-"automatic"}
UPDATE_RC=${2:-"true"}

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

export DEBIAN_FRONTEND=noninteractive

# Install go
echo "Installing go..."
mkdir -p /opt/go/modules /tmp/go
cd /tmp/go
curl -sSL -o /tmp/go.tar "https://update-to-point-to-a-real-location/go/go1.20.5.linux-amd64.tar.gz"
tar -xzf /tmp/go.tar -C "/opt/go" --strip-components=1
cd /tmp
rm -rf /tmp/go
updaterc "export PATH=\${PATH}:/opt/go/bin"
updaterc "export GOBIN=/opt/go/modules"
export GOBIN=/opt/go/modules
echo "export PATH=\${PATH}:\${GOBIN}" >> /home/${USERNAME}/.zshrc

echo "Done!"
