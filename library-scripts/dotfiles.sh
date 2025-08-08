#!/usr/bin/env bash
# Syntax: ./dotfiles.sh [non-root user] [version]

USERNAME=${1:-"automatic"}
DOTFILES_VERSION=${2:-"1.0.0"}

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

# Install dotfiles
mkdir -p /tmp/dotfiles
curl -sSL -o /tmp/dotfiles.tar.gz "https://sturdy5.github.io/dotfiles/dotfiles-${DOTFILES_VERSION}.tar.gz"
tar -xzf /tmp/dotfiles.tar.gz -C "/tmp/dotfiles" --strip-components=1
rsync --exclude ".git/" --exclude "bootstrap.sh" --exclude "README.md" --exclude ".idea" --exclude ".gitignore" -avh --no-perms /tmp/dotfiles /home/${USERNAME}

echo "" >> /home/${USERNAME}/.zshrc
echo "# Setup custom dotfiles" >> /home/${USERNAME}/.zshrc
echo "for file in ~/.{proxy,path,resources,extra}; do" >> /home/${USERNAME}/.zshrc
echo "  [ -r \"\$file\" ] && [ -f \"\$file\" ] && source \"\$file\";" >> /home/${USERNAME}/.zshrc
echo "done;" >> /home/${USERNAME}/.zshrc
echo "unset file;" >> /home/${USERNAME}/.zshrc
echo "Custom dotfiles added to /home/${USERNAME}/.zshrc"

echo "Done!"
