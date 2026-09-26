# VSCode-Server-DotNetCore

This is a Docker image of VSCode Server with the .NET LTS and STS SDKs pre-installed.

The image layers the .NET SDKs onto the [LinuxServer.io Code-Server][lsio-code-server-link] image, which packages [Coder Code-Server][code-server-link].

## Build and Distribution

- **Source Code**: [GitHub][github-link] for source, issues, and CI/CD pipelines.
- **Versioned Releases**: [GitHub Releases][releases-link] for version-tagged source archives.
- **Docker Images**: [Docker Hub][docker-hub-link] for the published container images.

### Build Status

[![Release Status][release-status-shield]][actions-link]\
[![Last Commit][last-commit-shield]][commits-link]

### Releases

[![GitHub Release][github-release-shield]][releases-link]\
[![GitHub Pre-Release][github-pre-release-shield]][releases-link]\
[![Docker Latest][docker-latest-shield]][docker-hub-link]\
[![Docker Develop][docker-develop-shield]][docker-hub-link]

### Release Notes

**Version: 1.1**:

**Summary**:

- Branch-scoped CI/CD, version-tagged images (`:SemVer2` alongside `latest` and `develop`), and per-version GitHub releases.

See [Release History][history] for complete release notes and older versions.

## Table of Contents

- [VSCode-Server-DotNetCore](#vscode-server-dotnetcore)
  - [Build and Distribution](#build-and-distribution)
    - [Build Status](#build-status)
    - [Releases](#releases)
    - [Release Notes](#release-notes)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Questions or Issues](#questions-or-issues)
  - [3rd Party Tools](#3rd-party-tools)
  - [License](#license)

## Installation

Images are published for `linux/amd64` and `linux/arm64`. `linux/arm/v7` is [not supported][lsio-armhf-link] by LinuxServer.io.

- `latest`: the `main` branch build.
- `develop`: the `develop` branch build, `linux/amd64` only.
- `X.Y.Z`: a specific `SemVer2` version, published alongside the moving tag.

```shell
docker pull ptr727/vscode-server-dotnetcore:latest
docker pull ptr727/vscode-server-dotnetcore:develop
```

Each build includes the LTS and STS [supported versions][dotnet-support-link] of the .NET SDK. The `latest` image is rebuilt from `main` every Monday, picking up the latest upstream Code-Server and .NET SDK updates. A `develop` image is published on demand.

## Usage

Follow the [LinuxServer.io Code-Server][lsio-code-server-link] instructions.

## Questions or Issues

Use [GitHub Discussions][discussions-link] for questions, and create a [GitHub Issue][issues-link] for problems with this image. Code-Server and base image issues belong with [LinuxServer.io][lsio-code-server-link].

## 3rd Party Tools

The third-party tools, libraries, and actions this project depends on.

| Tool | Role |
| --- | --- |
| [actionlint][actionlint-link] | GitHub Actions workflow linter. |
| [Coder Code-Server][code-server-link] | VS Code running in a browser. |
| [cspell][cspell-link] | Spell checker. |
| [Docker][docker-link] | Container build and runtime platform. |
| [editorconfig-checker][editorconfig-checker-link] | Line-ending and whitespace linter. |
| [GitHub Actions][github-actions-link] | CI and automation runner. |
| [GitHub Dependabot][dependabot-link] | Dependency update bot. |
| [LinuxServer.io Code-Server][lsio-code-server-link] | Code-Server container base image. |
| [markdownlint-cli2][markdownlint-link] | Markdown linter. |
| [Nerdbank.GitVersioning][nbgv-link] | Version computation from git height. |
| [.NET SDK][dotnet-link] | Development platform installed in the image. |

## License

Licensed under the [MIT License][license]\
![GitHub License][license-shield]

<!-- Shields -->

[docker-develop-shield]: https://img.shields.io/docker/v/ptr727/vscode-server-dotnetcore/develop?label=develop&logo=docker
[docker-latest-shield]: https://img.shields.io/docker/v/ptr727/vscode-server-dotnetcore/latest?label=latest&logo=docker
[github-pre-release-shield]: https://img.shields.io/github/v/release/ptr727/VSCode-Server-DotNetCore?include_prereleases&logo=github&label=GitHub%20Pre-Release
[github-release-shield]: https://img.shields.io/github/v/release/ptr727/VSCode-Server-DotNetCore?logo=github&label=GitHub%20Release
[last-commit-shield]: https://img.shields.io/github/last-commit/ptr727/VSCode-Server-DotNetCore?logo=github&label=Last%20Commit
[license-shield]: https://img.shields.io/github/license/ptr727/VSCode-Server-DotNetCore?label=License
[release-status-shield]: https://img.shields.io/github/actions/workflow/status/ptr727/VSCode-Server-DotNetCore/publish-release.yml?logo=github&label=Releases%20Build

<!-- Distribution -->

[actions-link]: https://github.com/ptr727/VSCode-Server-DotNetCore/actions
[commits-link]: https://github.com/ptr727/VSCode-Server-DotNetCore/commits/main
[discussions-link]: https://github.com/ptr727/VSCode-Server-DotNetCore/discussions
[docker-hub-link]: https://hub.docker.com/r/ptr727/vscode-server-dotnetcore
[github-link]: https://github.com/ptr727/VSCode-Server-DotNetCore
[issues-link]: https://github.com/ptr727/VSCode-Server-DotNetCore/issues
[releases-link]: https://github.com/ptr727/VSCode-Server-DotNetCore/releases

<!-- Repo -->

[history]: ./HISTORY.md
[license]: ./LICENSE

<!-- External -->

[actionlint-link]: https://github.com/rhysd/actionlint
[code-server-link]: https://github.com/coder/code-server
[cspell-link]: https://cspell.org
[dependabot-link]: https://github.com/dependabot
[docker-link]: https://www.docker.com
[dotnet-link]: https://dotnet.microsoft.com
[dotnet-support-link]: https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core
[editorconfig-checker-link]: https://github.com/editorconfig-checker/editorconfig-checker
[github-actions-link]: https://github.com/features/actions
[lsio-armhf-link]: https://www.linuxserver.io/blog/a-farewell-to-arm-hf
[lsio-code-server-link]: https://github.com/linuxserver/docker-code-server
[markdownlint-link]: https://github.com/DavidAnson/markdownlint-cli2
[nbgv-link]: https://github.com/dotnet/Nerdbank.GitVersioning
