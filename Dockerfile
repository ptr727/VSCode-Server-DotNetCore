#FROM buildpack-deps:bionic-scm
#FROM codercom/code-server:v2
FROM linuxserver/code-server:development

# Install wget
RUN sudo apt-get update && \
    sudo apt-get install -y wget && \
# Register the Microsoft repository, make sure it matches the platform
    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb && \
    sudo dpkg -i packages-microsoft-prod.deb && \
    sudo apt-get update && \
# Install .NET Core SDK and PowerShell
    sudo apt-get install -y \
    dotnet-sdk-3.0 \
    powershell

# Enable detection of running in a container
# See: https://github.com/dotnet/dotnet-docker/blob/master/3.0/sdk/bionic/amd64/Dockerfile
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip
