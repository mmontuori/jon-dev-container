# Dev Container

This contains all of the setup to allow for various configurations for doing development. Simply build the container, passing in the appropriate build arguments to get the container you need to run your application.

## Build Arguments

|Argument|Default Value|Description|
|--------|-------------|-----------|
|JAVA_VERSION | 21          | This is the version of Java to use. Java will be installed from the RHEL yum repos.|
|INSTALL_SCALA| false | Setting this to true will include the scala executable into the container |
|SCALA_VERSION| latest | This is the version of scala to install. |
|INSTALL_MAVEN| false | Setting this to true will include the maven executables into the container |
|MAVEN_VERSION| latest | This is the version of maven to install. Use version numbers from [Maven Releases](https://maven.apache.org/docs/history.html) |
|INSTALL_GRADLE| false | Setting this to true will include the gradle executables into the container |
|GRADLE_VERSION| latest | This is the version of gradle to install. Use version numbers without the v from [Gradle Releases](https://gradle.org/releases/) |
|INSTALL_NODE| false | Setting this to true will include the node executables into the container |
|NODE_VERSION| lts | This is the version of node to install. Use version numbers from [Node Version Manager](https://github.com/nvm-sh/nvm#usage) |
|INSTALL_PYTHON| false | Setting this to true will include the python executables into the container |
|PYTHON_VERSION| 3.10.2 | This is the version of python to install. Example values - 3.8.2, 3.10.0 |
|INSTALL_SBT| false | Setting this to true will include the sbt executables into the container |
|SBT_VERSION| latest | This is the version of sbt to install. |
|INSTALL_SPDX_GENERATOR| false | Setting this to true will include the spdx-sbom-generator utility |
|SPDX_GENERATOR_VERSION| 0.0.10 | This is teh verion of the spdx-sbom-generate to install. Use the version numbers without the `v` from [spdx-sbom-generator Releases](https://github.com/opensbom-generator/spdx-sbom-generator/releases)
|INSTALL_GO| false | Setting this to true will install the go language into the container |
|INSTALL_CLOCKIFY_CLI | false | Setting this to true will install the go language and the [clockify cli](https://clockify-cli.netlify.app/) into the container |
|INSTALL_OPENSHIFT_UTILS| false | Setting this to true will include oc and helm executables into the container |
|INSTALL_PODMAN | false | Setting this to true will install Docker in the container |
|INSTALL_DOTFILES | true | Setting this to false will keep the default dotfiles for the user |
|DOTFILES_VERSION| 1.0.0 | This is the version of sturdy5's dotfiles you want to install. Use version numbers from [sturdy5/dotfiles](https://sturdy5.github.io/dotfiles/) |

## Example Builds

Build a container for a dotnet application using 2.1

```bash
docker build --build-arg INSTALL_DOTNET=true --build-arg DOTNET_VERSION=2.1 -t dev-container:local .
```

Build a container for a java 8 application with maven

```bash
docker build --build-arg JAVA_VERSION=8 --build-arg INSTALL_MAVEN=true -t dev-container:local .
```

Build a container for a java app with maven and node

```bash
docker build --build-arg INSTALL_MAVEN=true --build-arg INSTALL_NODE=true -t dev-container:local .
```

## Running a Container

Once the container is built, you can get into it using the name you tagged it. In the examples above, we named the container `dev-container`. This uses the `zsh` shell.

```bash
docker run --rm -v ${PWD}:/home/dev/app -it dev-container:local /bin/zsh
```

Once in the container, you should have the tools necessary to develop your application.

## Running with VSCode

Once the container is built, you can use it within VSCode to do your development. First, start your container, mounting all the things that make sense. Here is what I use:

```shell
docker run -d -v ssh:/home/dev/.ssh -v /home/sturdy5/workspaces:/home/dev/workspaces -v app:/home/dev/apps --name dev-container dev-container:local
```

By default, the container will start up an nginx server so that it stays running.

Then you have to install the [Dev Containers extension in VSCode](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

Start a VSCode instance attached to your running container

1. Open VSCode locally
1. Click on the green icon at the bottom left
1. Select "Attach to Running Container..."
1. Select the dev-container you started above
