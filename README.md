# VSCode Server with .NET Core SDK and PowerShell Pre-Installed

This is a docker image of VSCode Server with the .NET Core SDK and PowerShell pre-installed.  
Docker image is based on [LinuxServer.io Code-Server](https://github.com/linuxserver/docker-code-server), which is based on [Coder.com Code-Server](https://github.com/cdr/code-server).  

## License

![GitHub License](https://img.shields.io/github/license/vkhurana/VSCode-Server-DotNetCore)  

## Build Status

[Code and Pipline is on GitHub](https://github.com/vkhurana/VSCode-Server-DotNetCore):  
![GitHub Last Commit](https://img.shields.io/github/last-commit/vkhurana/VSCode-Server-DotNetCore?logo=github)  
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/vkhurana/VSCode-Server-DotNetCore/Build%20and%20Publish%20Docker%20Images?logo=github)

## Container Images

Docker container images are published on [Docker Hub](https://hub.docker.com/r/vkhurana/vscode-server-dotnetcore).  
Images are tagged using `latest`, `3.1` and `7.0`.  
`latest` includes .NET Core 3.1 and .NET 7.0.  
Images are automatically rebuilt every Monday morning, picking up the latest updates.  
![Docker Pulls](https://img.shields.io/docker/pulls/vkhurana/vscode-server-dotnetcore?logo=docker)  
![Docker Image Version](https://img.shields.io/docker/v/vkhurana/vscode-server-dotnetcore/latest?logo=docker)

## Usage

Follow the [linuxserver/code-server](https://hub.docker.com/r/linuxserver/code-server) instructions.

## Background Info

- [DotNet in Docker](https://github.com/dotnet/dotnet-docker/blob/master/3.0/sdk/bionic/amd64/Dockerfile)
- [LSIO Code Server Docker](https://github.com/linuxserver/docker-code-server/blob/master/Dockerfile)
- [Coder Code Server Docker](https://github.com/cdr/code-server/blob/master/Dockerfile)
- [DotNet install](https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1804)
- [PowerShell install](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#ubuntu-1804)
- [Package Manager](https://dotnet.microsoft.com/download/linux-package-manager/ubuntu18-04/sdk-current)

## Notes

- codercom/code-server runs as root, not permission friendly when mapping volumes.
- linuxserver/code-server allows specifying PUID and GUID, ideal when using mapped volumes in e.g. UnRaid.
- Use `cat /etc/*-release` to determine the base image, installed packages must match the base image.
- Run DotNet Core by `dotnet` in the console.
- Run PowerShell by `pwsh` in the console.
- If installing PowerShell Core Preview use `powershell-preview` and `pwsh-preview` to launch.
- An alternative to building on top of the LSIO image, is to use a [dynamic overlay](https://blog.linuxserver.io/2019/09/14/customizing-our-containers/)
