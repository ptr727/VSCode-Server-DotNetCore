# VSCode Server with .NET Pre-Installed

Docker image of [Code-Server](https://github.com/coder/code-server) with the .NET SDKs pre-installed, based on the [LinuxServer.io Code-Server][linuxserver-code-server] image.

## License

Licensed under the [MIT License](https://github.com/vkhurana/VSCode-Server-Codex-DotNetCore/blob/main/LICENSE).

![GitHub License](https://img.shields.io/github/license/vkhurana/VSCode-Server-Codex-DotNetCore)

## Project

Code and pipeline are on [GitHub](https://github.com/vkhurana/VSCode-Server-Codex-DotNetCore). Docker images are published on [Docker Hub](https://hub.docker.com/r/vkhurana/vscode-server-codex-dotnetcore). Images are rebuilt weekly and on demand, picking up the latest upstream Code-Server and .NET SDK updates.

## Docker Tags

- `latest`: Latest `main` branch build.
- `develop`: Latest `develop` branch build.
- `<version>`: Specific `SemVer2` version (e.g. `1.1.0`).

## Platform Support

- `linux/amd64`
- `linux/arm64`

## Usage

Refer to the [GitHub README](https://github.com/vkhurana/VSCode-Server-Codex-DotNetCore#usage) and the [linuxserver/code-server][linuxserver-code-server] documentation for configuration and environment variables.

[linuxserver-code-server]: https://github.com/linuxserver/docker-code-server
