# VSCode Server with .NET Pre-Installed

This is a Docker image of VSCode Server with the .NET LTS and STS SDKs pre-installed.\
Docker image is based on [LinuxServer.io Code-Server](https://github.com/linuxserver/docker-code-server), which is based on [Coder.com Code-Server](https://github.com/cdr/code-server).\

## Codex
The Codex plugin and the C# plugins are pre-installed. To enable Codex:
- Add an `auth.json` in `/config/.codex/` folder
- `code-server` must be served over `https`

## License

![GitHub License](https://img.shields.io/github/license/vkhurana/VSCode-Server-Codex-DotNetCore)  

## Build Status

[Code and Pipeline is on GitHub](https://github.com/vkhurana/VSCode-Server-Codex-DotNetCore):  
![GitHub Last Commit](https://img.shields.io/github/last-commit/vkhurana/VSCode-Server-Codex-DotNetCore?logo=github)  
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/vkhurana/VSCode-Server-Codex-DotNetCore/publish-release.yml?logo=github)

## Container Images

Docker container images are published on [Docker Hub](https://hub.docker.com/r/vkhurana/VSCode-Server-Codex-DotNetCore).  
Multi-Architecture images are created for `linux/amd64` and `linux/arm64` (`linux/arm/v7` is [not supported](https://www.linuxserver.io/blog/a-farewell-to-arm-hf) by LSIO).  
Tags are `latest` for `main` branch and `develop` for `develop` branch, plus a `SemVer2` version tag (`X.Y.Z`) on every published image.\
E.g. `docker pull vkhurana/vscode-server-codex-dotnetcore:latest`  
E.g. `docker pull vkhurana/vscode-server-codex-dotnetcore:develop`\
E.g. `docker pull vkhurana/vscode-server-codex-dotnetcore:1.1.0`

Builds include the LTS and STS [supported versions](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) of .NET SDKs.

Images are automatically rebuilt every Monday morning, picking up the latest upstream updates.  
![Docker Pulls](https://img.shields.io/docker/pulls/vkhurana/vscode-server-codex-dotnetcore?logo=docker)  
![Docker Image Version](https://img.shields.io/docker/v/vkhurana/vscode-server-codex-dotnetcore/latest?logo=docker)

## Release History

- Version 1.1: Branch-scoped CI/CD, version-tagged images (`:SemVer2` alongside `latest` / `develop`), and per-version GitHub releases.
- Version 1.0: Multi-arch code-server image with the .NET LTS and STS SDKs pre-installed.

See [`HISTORY.md`](./HISTORY.md) for the full release history.

## Usage

Follow the [linuxserver/code-server](https://github.com/linuxserver/docker-code-server) instructions.
