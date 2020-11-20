#FROM codercom/code-server:v2
FROM linuxserver/code-server:latest

ARG LABEL_VERSION="3.1"
ARG INSTALL_VERSION="dotnet-sdk-3.1"

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
    # Install wget
    && apt-get install -y wget \
    # Register the Microsoft repository, make sure it matches the platform
    && wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    # Install .NET SDK and PowerShell
    # https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
    && apt-get install -y ${INSTALL_VERSION} powershell \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
