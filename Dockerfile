FROM linuxserver/code-server:latest

ARG LABEL_VERSION="3.1.5.0"
ARG INSTALL_VERSION="dotnet-sdk-3.1 dotnet-sdk-5.0"

LABEL name="VSCode-Server-DotNet" \
    version=${LABEL_VERSION} \
    description="VSCode Server with .NET Core SDK and PowerShell Pre-Installed" \
    maintainer="Pieter Viljoen <ptr727@users.noreply.github.com>"

    # Enable .NET detection of running in a container
    # See: https://github.com/dotnet/dotnet-docker/blob/master/3.0/sdk/bionic/amd64/Dockerfile
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # No installer frontend interaction
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    # Install pre-requisites
    && apt-get install -y wget apt-transport-https software-properties-common \
    # Register the Microsoft repository
    && wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -sr)/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    # Enable universe repositories
    && sudo add-apt-repository universe \
    # Update
    && apt-get update \
    && apt-get upgrade -y \
    # Install .NET SDK and PowerShell
    # https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
    # https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux
    && apt-get install -y ${INSTALL_VERSION} powershell \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
