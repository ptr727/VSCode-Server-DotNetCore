# Test in docker shell:
# docker run -it --rm --pull always --name Testing lscr.io/linuxserver/code-server:latest /bin/bash
# export DEBIAN_FRONTEND=noninteractive

# https://github.com/linuxserver/docker-code-server
FROM lscr.io/linuxserver/code-server:latest

ARG LABEL_VERSION="60.70"
ARG INSTALL_VERSION="dotnet-sdk-6.0 dotnet-sdk-7.0"

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
    && wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -sr)/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && touch /etc/apt/preferences \
    && echo "Package: *" >> /etc/apt/preferences \
    && echo "Pin: origin \"packages.microsoft.com\"" >> /etc/apt/preferences \
    && echo "Pin-Priority: 1001" >> /etc/apt/preferences \
    && cat /etc/apt/preferences \
    && cat /etc/apt/sources.list.d/microsoft-prod.list \
    # Update
    && apt-get update \
    && apt-get upgrade -y \
    # Install .NET SDK and PowerShell
    # https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
    # https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux
    && apt-get install -y ${INSTALL_VERSION} powershell \
    && dotnet --info \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
