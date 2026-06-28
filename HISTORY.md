# VSCode-Server-DotNetCore

Docker image of VSCode Server with the .NET LTS and STS SDKs pre-installed.

## Release History

- Version 1.1:
  - Reworked the CI/CD pipeline to a branch-scoped self-publishing model: a weekly scheduled run (and manual dispatch) publishes both `main` (stable, Docker `latest`) and `develop` (prerelease, Docker `develop`) - the multi-arch Docker image plus a GitHub release that anchors the version - while merges accumulate until the next run. The installed contents (code-server plus the .NET LTS and STS SDKs) are unchanged.
  - Version-tagged the container: images now also publish a `:SemVer2` tag (`X.Y.<height>`) alongside the moving `latest` / `develop` tags, and each version gets a GitHub release.
  - Added `WORKFLOW.md` (the canonical CI/CD specification), `repo-config/` (rulesets and repository settings as code), and this `HISTORY.md`.
- Version 1.0:
  - Docker image of [LinuxServer.io Code-Server](https://github.com/linuxserver/docker-code-server) with the .NET LTS and STS SDKs pre-installed via `dotnet-install.sh`.
  - Multi-architecture images for `linux/amd64` and `linux/arm64`, published to Docker Hub as the moving `latest` (main) and `develop` tags and rebuilt weekly to pick up upstream base-image updates.
