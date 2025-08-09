#!/usr/bin/env bash
# Syntax: ./podman.sh [non-root user] [Update rc files flag]

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

# Install podman
dnf install -y podman fuse-overlayfs
export PODMAN_IGNORE_CGROUPSV1_WARNING="true"

# setup uid and gids
echo ${USERNAME}:10000:5000 > /etc/subuid
echo ${USERNAME}:10000:5000 > /etc/subgid

# setup containers.conf
mkdir -p /etc/containers
echo "[containers]" > /etc/containers/containers.conf
echo "netns=\"host\"" >> /etc/containers/containers.conf
echo "userns=\"host\"" >> /etc/containers/containers.conf
echo "ipcns=\"host\"" >> /etc/containers/containers.conf
echo "utsns=\"host\"" >> /etc/containers/containers.conf
echo "cgroupns=\"host\"" >> /etc/containers/containers.conf
echo "cgroups=\"disabled\"" >> /etc/containers/containers.conf
echo "log_driver = \"k8s-file\"" >> /etc/containers/containers.conf
echo "[engine]" >> /etc/containers/containers.conf
echo "cgroup_manager = \"cgroupfs\"" >> /etc/containers/containers.conf
echo "events_logger=\"file\"" >> /etc/containers/containers.conf
echo "runtime=\"crun\"" >> /etc/containers/containers.conf

# setup podman-containers.conf
mkdir -p /home/${USERNAME}/.config/containers
echo "[containers]" > /home/${USERNAME}/.config/containers/containers.conf
echo "volumes = [" >> /home/${USERNAME}/.config/containers/containers.conf
echo "	\"/proc:/proc\"," >> /home/${USERNAME}/.config/containers/containers.conf
echo "]" >> /home/${USERNAME}/.config/containers/containers.conf
echo "default_sysctls = []" >> /home/${USERNAME}/.config/containers/containers.conf

chown ${USERNAME}:${USERNAME} -R /home/${USERNAME}
chmod 644 /etc/containers/containers.conf
mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers
touch /var/lib/shared/overlay-images/images.lock
touch /var/lib/shared/overlay-layers/layers.lock
touch /var/lib/shared/vfs-images/images.lock
touch /var/lib/shared/vfs-layers/layers.lock

# setup to use fuse-overlayfs
echo "[storage]" > /etc/containers/storage.conf
echo "driver = \"overlay\"" >> /etc/containers/storage.conf
echo "[storage.options.overlay]" >> /etc/containers/storage.conf
echo "mount_program = \"/usr/bin/fuse-overlayfs\"" >> /etc/containers/storage.conf
sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
export _CONTAINERS_USERNS_CONFIGURED=""

echo "Done!"
