#!/bin/sh
set -e

USERNAME="vscode"
DOTNET_VERSION="6.0"

while [ "$1" != "" ]; do
    case $1 in
        --user )    shift
                    USERNAME=$1
                    ;;
        --version ) shift
                    DOTNET_VERSION=$1
                    ;;
    esac
    shift
done

# Install the microsoft package definitions
wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install the SDK and runtime
apt-get update
apt-get install -y apt-transport-https
apt-get update
apt-get install -y dotnet-sdk-${DOTNET_VERSION} aspnetcore-runtime-${DOTNET_VERSION}
