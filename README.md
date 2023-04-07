# VSCode Server with .NET Core SDK and PowerShell Pre-Installed

This is a docker image of VSCode Server with the .NET LTS and STS SDK's pre-installed.  
Docker image is based on [LinuxServer.io Code-Server](https://github.com/linuxserver/docker-code-server), which is based on [Coder.com Code-Server](https://github.com/cdr/code-server).  

## License

![GitHub License](https://img.shields.io/github/license/ptr727/VSCode-Server-DotNetCore)  

## Build Status

[Code and Pipline is on GitHub](https://github.com/ptr727/VSCode-Server-DotNetCore):  
![GitHub Last Commit](https://img.shields.io/github/last-commit/ptr727/VSCode-Server-DotNetCore?logo=github)  
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ptr727/VSCode-Server-DotNetCore/BuildPublishPipeline.yml?logo=github)

## Container Images

Docker container images are published on [Docker Hub](https://hub.docker.com/r/ptr727/vscode-server-dotnetcore).  
Multi-Arch images are available for `linux/amd64`, `linux/arm64`, and `linux/arm/v7`.  
Builds include the LTS (.NET 6.0) and STS (.NET 7.0) [supported versions](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) of .NET SDK's.  
Images are automatically rebuilt every Monday morning, picking up the latest updates.  
![Docker Pulls](https://img.shields.io/docker/pulls/ptr727/vscode-server-dotnetcore?logo=docker)  
![Docker Image Version](https://img.shields.io/docker/v/ptr727/vscode-server-dotnetcore/latest?logo=docker)

## Usage

Follow the [linuxserver/code-server](https://github.com/linuxserver/docker-code-server) instructions.

## Notes

- Multi-Arch image support was added, and PowerShell support was removed (not supported).
