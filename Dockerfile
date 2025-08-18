FROM redhat/ubi10:10.0

ARG JAVA_VERSION=21
ARG VARIANT=$JAVA_VERSION
ENV VARIANT=$VARIANT
# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="true"

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# copy the scripts to the container
COPY library-scripts/*.sh /tmp/library-scripts/
COPY files/k8s-utils/*.sh /tmp/k8s-utils/

# Arguments which can change the tools installed in the container
ARG INSTALL_MAVEN="false"
ARG INSTALL_GRADLE="false"
ARG INSTALL_NODE="false"
ARG INSTALL_PYTHON="false"
ARG INSTALL_SCALA="false"
ARG INSTALL_SBT="false"
ARG INSTALL_SPDX_GENERATOR="false"
ARG INSTALL_GO="false"
ARG INSTALL_K8S_UTILS="false"
ARG INSTALL_PODMAN="false"
ARG INSTALL_DOTFILES="true"

ARG MAVEN_VERSION="latest"
ARG GRADLE_VERSION="latest"
ARG NODE_VERSION=""
ARG PYTHON_VERSION="3"
ARG SCALA_VERSION=""
ARG SBT_VERSION=""
ARG SPDX_GENERATOR_VERSION="0.0.10"
ARG DOTFILES_VERSION="1.0.0"
ARG GO_VERSION="1.24.6"
ARG HELM_VERSION="3.17.4"

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true \
    PATH="${NVM_DIR}/current/bin:${PATH}"
ENV SDKMAN_DIR="/usr/local/sdkman"
ENV PATH="${SDKMAN_DIR}/candidates/java/current/bin:${PATH}:${SDKMAN_DIR}/candidates/maven/current/bin:${SDKMAN_DIR}/candidates/gradle/current/bin"

RUN dnf update -y \
    && dnf install -y java-$JAVA_VERSION-openjdk \
    # Install common packages, non-root user
    && bash /tmp/library-scripts/common.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Install tmux
    && bash /tmp/library-scripts/tmux.sh "3.5a-4.fc42" "${USERNAME}" "true" \
    # Install dotfiles
    && if [ "${INSTALL_DOTFILES}" = "true" ]; then bash /tmp/library-scripts/dotfiles.sh "${USERNAME}" "${DOTFILES_VERSION}"; fi \
    # Install gradle
    && if [ "${INSTALL_GRADLE}" = "true" ]; then bash /tmp/library-scripts/gradle.sh "${GRADLE_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    # Install maven
    && if [ "${INSTALL_MAVEN}" = "true" ]; then bash /tmp/library-scripts/maven.sh "${MAVEN_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    && if [ "${INSTALL_MAVEN}" = "true" ]; then mkdir -p ${MAVEN_CONFIG}; fi \
    && if [ "${INSTALL_MAVEN}" = "true" ]; then chown -R ${USERNAME} ${MAVEN_CONFIG}; fi \
    # Install node
    && if [ "$INSTALL_NODE" = "true" ]; then bash /tmp/library-scripts/node.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}"; fi \
    # Install python
    && if [ "$INSTALL_PYTHON" = "true" ]; then bash /tmp/library-scripts/python.sh "${PYTHON_VERSION}" "${USERNAME}"; fi \
    # Install scala
    && if [ "${INSTALL_SCALA}" = "true" ]; then bash /tmp/library-scripts/scala.sh "${SCALA_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    # Install sbt
    && if [ "${INSTALL_SBT}" = "true" ]; then bash /tmp/library-scripts/sbt.sh "${SBT_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    # Install the spdx generator
    && if [ "${INSTALL_SPDX_GENERATOR}" = "true" ]; then bash /tmp/library-scripts/spdx-generator.sh "${SPDX_GENERATOR_VERSION}" "${USERNAME}" "true"; fi \
    # Install go
    && if [ "${INSTALL_GO}" = "true" ]; then bash /tmp/library-scripts/go.sh "${GO_VERSION}" "${USERNAME}" "true"; fi \
    # Install openshift utils
    && if [ "${INSTALL_K8S_UTILS}" = "true" ]; then bash /tmp/library-scripts/k8s-utils.sh "${HELM_VERSION}" "${USERNAME}" "true"; fi \
    && if [ "${INSTALL_K8S_UTILS}" = "true" ]; then cp -r /tmp/k8s-utils /home/${USERNAME}; fi \
    # Install podman
    && if [ "${INSTALL_PODMAN}" = "true" ]; then bash /tmp/library-scripts/podman.sh "${USERNAME}" "true"; fi \
    # install nginx
    && dnf install -y nginx \
    # Clean up
    && rm -rf /tmp/library-scripts \
    && rm -rf /tmp/k8s-utils \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
    && rm -rf /var/lib/rpm/__db* \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

USER ${USERNAME}

RUN export HOME=/home/${USERNAME} \
    && mkdir -p ${HOME}/.ssh ${HOME}/workspaces ${HOME}/apps

VOLUME /var/lib/containers
VOLUME /home/podman/.local/share/containers

EXPOSE 8080
CMD sudo nginx -g 'daemon off;'
ENV HOME=/home/${USERNAME}

WORKDIR /home/${USERNAME}
