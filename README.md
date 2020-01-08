# VSCode Server with .NET Core SDK and PowerShell Pre-Installed

Docker image is based on [LinuxServer.io Code-Server](https://github.com/linuxserver/docker-code-server), which is based on [Coder.com Code-Server](https://github.com/cdr/code-server).  

## License

![GitHub](https://img.shields.io/github/license/ptr727/VSCode-Server-DotNetCore)  

## Build Status

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/ptr727/vscode-server-dotnetcore)  
Pull from [Docker Hub](https://hub.docker.com/r/ptr727/vscode-server-dotnetcore)  
Code at [GitHub](https://github.com/ptr727/VSCode-Server-DotNetCore)  

## Usage

Follow the [linuxserver/code-server](https://hub.docker.com/r/linuxserver/code-server) instructions.

## Background Info

- [DotNet in Docker](https://github.com/dotnet/dotnet-docker/blob/master/3.0/sdk/bionic/amd64/Dockerfile)
- [LSI Code Server Docker](https://github.com/linuxserver/docker-code-server/blob/master/Dockerfile)
- [Code Code Server Docker](https://github.com/cdr/code-server/blob/master/Dockerfile)
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
- An alternative to building on top of the LSI image, is to use a [dynamic overlay](https://blog.linuxserver.io/2019/09/14/customizing-our-containers/)
