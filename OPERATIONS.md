# Operations

How this repository is run day to day. [`WORKFLOW.md`](./WORKFLOW.md) is the CI/CD contract, and [`GOVERNANCE.md`](./GOVERNANCE.md) holds the cross-cutting rules.

## Local Verification

This repo compiles nothing, so it has no clean-compile task. The gate is the document lint set plus a Docker smoke build of the image, and it reports clean before a commit. The `Lint: All` VS Code task in [`.vscode/tasks.json`](./.vscode/tasks.json) runs the lint set from the official images, which needs no local Node or Go install. The commands below are written for a POSIX shell or PowerShell, since `cmd.exe` expands neither `$PWD` nor the quoted glob:

```shell
docker run --rm -v "$PWD":/work -w /work davidanson/markdownlint-cli2 '**/*.md'
docker run --rm -v "$PWD":/work -w /work ghcr.io/streetsidesoftware/cspell --no-progress README.md HISTORY.md
docker run --rm -v "$PWD":/work -w /work rhysd/actionlint
docker run --rm -v "$PWD":/check -w /check mstruebing/editorconfig-checker:latest
```

Run `actionlint` after any edit under [`.github/workflows/`](./.github/workflows/). After a [`Dockerfile`](./Dockerfile) edit, build the image for one platform to prove it still builds, which is what CI's smoke build does on every push:

```shell
docker buildx build --load --progress plain --platform linux/amd64 --tag testing:latest .
docker run -it --rm --name testing testing:latest /bin/bash
docker run -d --rm -p 8443:8443 --name testing testing:latest
```

The first `docker run` opens a shell in the image. The second starts code-server and serves it on `http://localhost:8443/`.

**What CI cannot exercise.** The Docker Hub push, the Docker Hub overview push, and the GitHub release run only on a real publish, so a pull request proves the image builds for `linux/amd64` and never proves it builds for `linux/arm64` or uploads. Whether code-server actually starts and the .NET SDKs work inside the running container is covered by no automated check. Start the image detached, as above, and open `http://localhost:8443/` to check it by hand when a change could affect either.

## Runbooks

**Cutting a release.** Merges do not publish. `publish-release.yml` runs on a weekly schedule and on manual dispatch, and each run publishes one branch, the trigger ref. The schedule rebuilds `main` only, which refreshes the `latest` image and picks up `lscr.io/linuxserver/code-server` base-image updates, so accumulated changes on `main` ship in the next scheduled run. A dispatch publishes the branch it is started from: `main` builds a stable release tagged `latest`, and `develop` a prerelease tagged `develop`. A `main` image is multi-arch, `linux/amd64` and `linux/arm64`, and a `develop` image is `linux/amd64` only. A dispatch from any other branch publishes nothing. When a release for the version already exists, a scheduled run skips the GitHub release and still pushes the image, so a rebuild refreshes the base image without a new release, and a dispatch refreshes the existing release. The Docker Hub overview is pushed from [`Docker/README.md`](./Docker/README.md) after a `main` publish only. Update the release notes in [`README.md`](./README.md) and the full entry in [`HISTORY.md`](./HISTORY.md) in the change that ships the behavior.

**Bumping the version floor.** [`version.json`](./version.json) carries the NBGV major.minor floor, and NBGV appends the git height as the patch. Raise the floor only on the maintainer's instruction, for a functional change or a one-time overhaul of the build or release process, in the pull request that introduces it, typically on `develop`. Routine dependency, workflow, and doc changes leave it alone.

## Backup and Recovery

## Logs and Debugging

## Tool Usage

## Configuration Layout

**CI runs on push, on every branch.** [`test-pull-request.yml`](./.github/workflows/test-pull-request.yml) has no `pull_request` trigger and no paths filter, so the lint gate and the smoke build run on every push, and a pull request that edits a reusable workflow tests its own copy. The workflow's own comment calls this the documented exception. A fork pull request cannot push here, so it produces no run and cannot satisfy the required check. A maintainer lands such a contribution on an in-repo branch, which pushes and so validates, before merging it. A branch-deletion push is skipped. The pipeline passes no artifacts between jobs, so it has no artifact retention to manage.

**Dependabot** runs the `github-actions` ecosystem only, once per branch, so `main` and `develop` each receive their own update pull requests. A Dependabot security pull request always targets `main`, and the merge-bot selects the merge method from each pull request's base branch, so it merges either kind. Every Dependabot pull request that originates from this repository auto-merges once its required checks pass, semver-major included, through [`merge-bot-pull-request.yml`](./.github/workflows/merge-bot-pull-request.yml). An action bump is not a shipped input, so it ships in the next scheduled publish rather than on merge.
