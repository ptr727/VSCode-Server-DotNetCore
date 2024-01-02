# Test MSCR image in shell:
# docker run -it --rm --pull always --name Testing mcr.microsoft.com/dotnet/sdk:latest /bin/bash

# Test LSIO image in shell:
# docker run -it --rm --pull always --name Testing lscr.io/linuxserver/code-server:latest /bin/bash
# export DEBIAN_FRONTEND=noninteractive

# Test image in shell:
# docker run -it --rm --pull always --name Testing ptr727/vscode-server-dotnetcore:develop /bin/bash

# Build Dockerfile
# docker buildx build --platform linux/amd64,linux/arm64 --tag testing:latest .

# Test linux/amd64 target
# docker buildx build --load --progress plain --no-cache --platform linux/amd64 --tag testing:latest .
# docker run -it --rm --name Testing testing:latest /bin/bash
# docker run -d --name Testing testing:latest
# http://localhost:8443/
# docker stop Testing
# docker rm Testing



# https://github.com/linuxserver/docker-code-server
# https://github.com/linuxserver/docker-code-server/blob/master/Dockerfile
FROM lscr.io/linuxserver/code-server:latest

# Image label
# TODO: Get current LTS and STS versions dynamically
ARG LABEL_VERSION="70.80"
LABEL name="VSCode-Server-DotNet" \
    version=${LABEL_VERSION} \
    description="VSCode Server with .NET SDK Pre-Installed" \
    maintainer="Pieter Viljoen <ptr727@users.noreply.github.com>"

# See: https://github.com/dotnet/dotnet-docker/blob/main/src/sdk/7.0/jammy/amd64/Dockerfile
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS= \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # No installer frontend interaction
    DEBIAN_FRONTEND=noninteractive

# Prerequisites, keep up with LSIO base image, currently Ubuntu Jammy 22.04
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#dependencies
# https://github.com/linuxserver/docker-code-server/blob/master/Dockerfile
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgcc-s1 \
        libgssapi-krb5-2 \
        libicu70 \
        liblttng-ust1 \
        libssl3 \
        libstdc++6 \
        libunwind8 \
        wget  \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set .NET root to same path used for installation
# https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script#set-environment-variables
ENV DOTNET_ROOT=/usr/share/dotnet

# Install .NET LTS and STS versions
# https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script
# https://github.com/dotnet/install-scripts/blob/main/src/dotnet-install.sh
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \ 
    && chmod +x ./dotnet-install.sh \
    && ./dotnet-install.sh --install-dir /usr/share/dotnet --version latest --channel LTS \
    && ./dotnet-install.sh --install-dir /usr/share/dotnet --version latest --channel STS \
    && rm ./dotnet-install.sh \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && dotnet --list-runtimes \
    && dotnet --list-sdks \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
