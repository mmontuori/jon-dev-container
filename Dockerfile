ARG JAVA_VERSION=21
ARG VARIANT=$JAVA_VERSION
FROM redhat/ubi10:10.0

ENV VARIANT=$VARIANT
# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="true"

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Don't share telemtry information with Microsoft
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# copy the scripts to the container
COPY library-scripts/*.sh /tmp/library-scripts/

# Arguments which can change the tools installed in the container
ARG INSTALL_DOTNET="false"
ARG INSTALL_MAVEN="false"
ARG INSTALL_GRADLE="false"
ARG INSTALL_NODE="false"
ARG INSTALL_PYTHON="false"
ARG INSTALL_SCALA="false"
ARG INSTALL_SBT="false"
ARG INSTALL_SPDX_GENERATOR="false"
ARG INSTALL_GO="false"
ARG INSTALL_OPENSHIFT_UTILS="false"
ARG INSTALL_DOCKER="false"
ARG INSTALL_CLOCKIFY_CLI="false"
ARG INSTALL_DOTFILES="true"

ARG DOTNET_VERSION="6.0"
ARG MAVEN_VERSION="latest"
ARG GRADLE_VERSION="latest"
ARG NODE_VERSION=""
ARG PYTHON_VERSION="3.10.2"
ARG SCALA_VERSION=""
ARG SBT_VERSION=""
ARG SPDX_GENERATOR_VERSION="0.0.10"
ARG DOTFILES_VERSION="1.0.0"

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true \
    PATH="${NVM_DIR}/current/bin:${PATH}"
ENV SDKMAN_DIR="/usr/local/sdkman"
ENV PATH="${SDKMAN_DIR}/candidates/java/current/bin:${PATH}:${SDKMAN_DIR}/candidates/maven/current/bin:${SDKMAN_DIR}/candidates/gradle/current/bin"
ENV PIPX_HOME=/usr/local/py-utils \
    PIPX_BIN_DIR=/usr/local/py-utils/bin
ENV PATH=${PATH}:${PIPX_BIN_DIR}

RUN dnf update
    && dnf install -y java-$VARIANT-openjdk
    # Install common packages, non-root user
    && bash /tmp/library-scripts/common-rhel.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Install dotfiles
    && if [ "${INSTALL_DOTFILES}" = "true" ]; then bash /tmp/library-scripts/dotfiles.sh "${USERNAME}" "${DOTFILES_VERSION}"
    # Install dotnet
    && if [ "${INSTALL_DOTNET}" = "true" ]; then bash /tmp/library-scripts/dotnet.sh --user "${USERNAME}" --version "${DOTNET_VERSION}"; fi \
    # Install gradle
    && if [ "${INSTALL_GRADLE}" = "true" ]; then bash /tmp/library-scripts/gradle-debian.sh "${GRADLE_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    # Install maven
    && if [ "${INSTALL_MAVEN}" = "true" ]; then bash /tmp/library-scripts/maven-debian.sh "${MAVEN_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    && if [ "${INSTALL_MAVEN}" = "true" ]; then mkdir -p ${MAVEN_CONFIG}; fi \
    && if [ "${INSTALL_MAVEN}" = "true" ]; then chown -R ${USERNAME} ${MAVEN_CONFIG}; fi \
    # Install node
    && if [ "$INSTALL_NODE" = "true" ]; then bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}"; fi \
    # Install python
    && if [ "$INSTALL_PYTHON" = "true" ]; then bash /tmp/library-scripts/python-debian.sh "${PYTHON_VERSION}" "/usr/local/python${PYTHON_VERSION}" "${PIPX_HOME}" "${USERNAME}"; fi \
    # Install scala
    && if [ "${INSTALL_SCALA}" = "true" ]; then bash /tmp/library-scripts/scala-debian.sh "${SCALA_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    # Install sbt
    && if [ "${INSTALL_SBT}" = "true" ]; then bash /tmp/library-scripts/sbt-debian.sh "${SBT_VERSION}" "${SDKMAN_DIR}" ${USERNAME} "true"; fi \
    # Install the spdx generator
    && if [ "${INSTALL_SPDX_GENERATOR}" = "true" ]; then bash /tmp/library-scripts/spdx-generator-debian.sh "${SPDX_GENERATOR_VERSION}" "${USERNAME}" "true"; fi

# Create a place to store the app and change permissions so the end user can use it
RUN mkdir /home/${USERNAME}/app && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# Remove library scripts for final image
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /root/.gnupg # /tmp/library-scripts

WORKDIR /home/${USERNAME}/app
