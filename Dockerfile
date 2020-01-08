#FROM codercom/code-server:v2
FROM linuxserver/code-server:development

LABEL name="VSCode-Server-DotNet" \
    version="3.0" \
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
    # Install .NET Core SDK and PowerShell
    && apt-get install -y dotnet-sdk-3.1 powershell \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
