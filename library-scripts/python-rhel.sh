#!/usr/bin/env bash

PYTHON_VERSION=${1:-"3.12"}
USERNAME=${2:-"automatic"}
UPDATE_RC=${3:-"true"}
INSTALL_PYTHON_TOOLS=${4:-"true"}

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

# Install python from source if needed
if [ "${PYTHON_VERSION}" != "none" ]; then

    PYTHON_INSTALL_PATH="/usr/bin/python${PYTHON_VERSION}"
    if [ -d "${PYTHON_INSTALL_PATH}" ]; then
        echo "Path ${PYTHON_INSTALL_PATH} already exists. Assuming Python already installed."
    else
        echo "Installing Python ${PYTHON_VERSION} ..."
        microdnf install -y python${PYTHON_VERSION}
        
        ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python
    fi
fi

# If not installing python tools, exit
if [ "${INSTALL_PYTHON_TOOLS}" != "true" ]; then
    echo "Done!"
    exit 0;
fi

DEFAULT_UTILS="\
    pylint \
    flake8 \
    autopep8 \
    black \
    yapf \
    mypy \
    pydocstyle \
    pycodestyle \
    bandit \
    pipenv \
    virtualenv"

export PIPX_HOME=/usr/local/py-utils
export PIPX_BIN_DIR=${PIPX_HOME}/bin
export PATH=${PIPX_BIN_DIR}:${PATH}

# Configure trusted sites to work inside bluecross
echo "[global]" >> /etc/pip.conf
echo "trusted-host = pypi.python.org" >> /etc/pip.conf
echo "               pypi.org" >> /etc/pip.conf
echo "               files.pythonhosted.org" >> /etc/pip.conf

# Update pip
echo "Updating pip..."
python -m ensurepip --upgrade

# Create pipx group, dir, and set sticky bit
if ! cat /etc/group | grep -e "^pipx:" > /dev/null 2>&1; then
    groupadd -r pipx
fi
usermod -a -G pipx ${USERNAME}
umask 0002
mkdir -p ${PIPX_BIN_DIR}
chown :pipx ${PIPX_HOME} ${PIPX_BIN_DIR}
chmod g+s ${PIPX_HOME} ${PIPX_BIN_DIR}

# Install tools
echo "Installing Python tools..."
export PYTHONUSERBASE=/tmp/pip-tmp
export PIP_CACHE_DIR=/tmp/pip-tmp/cache
pip3 install --disable-pip-version-check --no-warn-script-location --no-cache-dir --user pipx
/tmp/pip-tmp/bin/pipx install --pip-args=--no-cache-dir pipx
echo "${DEFAULT_UTILS}" | xargs -n 1 /tmp/pip-tmp/bin/pipx install --system-site-packages --pip-args '--no-cache-dir --force-reinstall'
rm -rf /tmp/pip-tmp

updaterc "$(cat << EOF
export PIPX_HOME="${PIPX_HOME}"
export PIPX_BIN_DIR="${PIPX_BIN_DIR}"
if [[ "\${PATH}" != *"\${PIPX_BIN_DIR}"* ]]; then export PATH="\${PATH}:\${PIPX_BIN_DIR}"; fi
EOF
)"