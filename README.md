# Dev Container

This contains all of the setup to allow for various configurations for doing development. Simply build the container, passing in the appropriate build arguments to get the container you need to run your application.

## Build Arguments

|Argument|Default Value|Description|
|--------|-------------|-----------|
|JAVA_VERSION | 18          | This is the version of Java to use. Java is always required to run the scanner. Use any of the valid tags for the [OpenJDK Docker Image](https://hub.docker.com/_/openjdk?tab=tags)|
|INSTALL_DOTNET| false | Setting this to true will include the dotnet executables into the container |
|DOTNET_VERSION| 6.0 | This is the version of dotnet to install. Example values - 2.1, 5.0, 6.0|
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

## Example Builds

Build a container for a dotnet application using 2.1

```bash
docker build --build-arg INSTALL_DOTNET=true --build-arg DOTNET_VERSION=2.1 -t dev-container .
```

Build a container for a java 8 application with maven

```bash
docker build --build-arg JAVA_VERSION=8 --build-arg INSTALL_MAVEN=true -t dev-container .
```

Build a container for a java app with maven and node

```bash
docker build --build-arg INSTALL_MAVEN=true --build-arg INSTALL_NODE=true -t dev-container .
```

## Running a Container

Once the container is built, you can get into it using the name you tagged it. In the examples above, we named the container `dev-container`. This uses the `zsh` shell.

```bash
docker run --rm -v ${PWD}:/home/dev/app -it dev-container /bin/zsh
```

Once in the container, you should have the tools necessary to develop your application.
