# Operations

How this repository is run day to day. [`WORKFLOW.md`](./WORKFLOW.md) is the CI/CD contract, and [`GOVERNANCE.md`](./GOVERNANCE.md) holds the cross-cutting rules.

## Local Verification

This repo compiles nothing, so it has no clean-compile task. The gate is the document lint set plus a Docker smoke build of the image, and it reports clean before a commit. The `Lint: All` VS Code task in [`.vscode/tasks.json`](./.vscode/tasks.json) runs the lint set from the official images, which needs no local Node or Go install. The commands below are written for a POSIX shell or PowerShell, since `cmd.exe` expands neither `$PWD` nor the quoted glob:

```shell
docker run --rm -v "$PWD":/work -w /work davidanson/markdownlint-cli2 '**/*.md'
docker run --rm -v "$PWD":/work -w /work ghcr.io/streetsidesoftware/cspell --no-progress README.md HISTORY.md
docker run --rm -v "$PWD":/work -w /work rhysd/actionlint
docker run --rm -v "$PWD":/check -w /check ghcr.io/editorconfig-checker/editorconfig-checker:latest
```

CI also runs the hub's prose gate on every pull request, scoped to the lines the pull request changes. Run the same gate with this repository as the working directory, from a checkout of `ptr727/ProjectTemplate` at the commit this repository's workflows pin: `python3 <hub-checkout>/scripts/prose_lint.py --diff "$(git merge-base origin/<target> HEAD)"`. `<target>` is the branch the pull request merges into, `develop` for a feature branch and `main` for a promotion. The merge base keeps the run to the branch's own lines. A bare `origin/<target>` would also flag what the target changed since the branch point. CI diffs against the target's current tip instead, so the two can differ once the target has moved. A feature pull request that adds or edits a comment line needs the `comments` label, and its local run needs `--allow-comments`. A promotion needs no label, since the gate stands the comment rule down there, so its local run always takes `--allow-comments`. The gate reads the label live, so re-run the failed job after adding it rather than pushing again.

Run `actionlint` after any edit under [`.github/workflows/`](./.github/workflows/). After a [`Docker/Dockerfile`](./Docker/Dockerfile) edit, build the image for one platform to prove it still builds. CI's smoke build does the same on a pull request that changes the image's inputs:

```shell
docker buildx build --load --progress plain --platform linux/amd64 --file Docker/Dockerfile --tag testing:latest .
docker run -it --rm --name testing testing:latest /bin/bash
docker run -d --rm -p 8443:8443 --name testing testing:latest
```

The first `docker run` opens a shell in the image. The second starts code-server and serves it on `http://localhost:8443/`.

**What CI cannot exercise.** The Docker Hub push, the Docker Hub overview push, and the GitHub release run only on a real publish. So a pull request that changes the image's inputs proves the image builds for `linux/amd64`. It never proves the image builds for `linux/arm64` or uploads. A pull request that only bumps a hub workflow pin is not smoke-built, per `WORKFLOW.md` D1.4. Dependabot auto-merges such a bump, and a dispatch cannot hold it, since a dispatched run posts a context no ruleset requires. So once it merges, dispatch [`test-pull-request.yml`](./.github/workflows/test-pull-request.yml) on its base branch, `develop` or `main`, to build at the new pin. Whether code-server actually starts and the .NET SDKs work inside the running container is covered by no automated check. Start the image detached, as above, and open `http://localhost:8443/` to check it by hand when a change could affect either.

## Runbooks

**Cutting a release.** Merges do not publish. [`publish-release.yml`](./.github/workflows/publish-release.yml) runs on a weekly schedule and on manual dispatch, and each run publishes one branch, the trigger ref. The hub's release-plan task decides whether a run publishes, and the hub's validate gate runs on the branch tip before anything is built. The schedule rebuilds `main` only, which refreshes the `latest` image and picks up `lscr.io/linuxserver/code-server` base-image updates, so accumulated changes on `main` ship in the next scheduled run. A dispatch publishes the branch it is started from: `main` builds a stable release tagged `latest`, and `develop` a prerelease tagged `develop`. A `main` image is multi-arch, `linux/amd64` and `linux/arm64`, and a `develop` image is `linux/amd64` only. A dispatch from any other branch publishes nothing. The build, the Docker push, and the GitHub release are the hub's reusable tasks, pinned by commit in the workflow, and Dependabot bumps the pin. When a release for the version already exists, a scheduled run skips the GitHub release and still pushes the image, so a rebuild refreshes the base image without a new release, and a dispatch refreshes the existing release. The Docker Hub overview is pushed from [`Docker/README.md`](./Docker/README.md) after a `main` publish only. Update the release notes in [`README.md`](./README.md) and the full entry in [`HISTORY.md`](./HISTORY.md) in the change that ships the behavior.

**Bumping the version floor.** [`version.json`](./version.json) carries the NBGV major.minor floor, and NBGV appends the git height as the patch. Raise the floor only on the maintainer's instruction, for a functional change or a one-time overhaul of the build or release process, in the pull request that introduces it, typically on `develop`. Routine dependency, workflow, and doc changes leave it alone.

## Backup and Recovery

## Logs and Debugging

## Tool Usage

## Configuration Layout

**CI runs on every pull request.** [`test-pull-request.yml`](./.github/workflows/test-pull-request.yml) triggers on `pull_request` and `workflow_dispatch`, so a branch with no pull request gets no run. The lint gate runs on every pull request. The smoke build runs only where `Docker/Dockerfile` or `version.json` changed, or on a dispatch, per `WORKFLOW.md` D1.1 and D1.4. So a workflow-only or docs-only pull request is linted but not built. Only a `pull_request` run posts the ruleset-bound `Check pull request workflow status job` context, per `WORKFLOW.md` D1.5. A dispatch posts `Check workflow status job` instead, so it can never satisfy the required check on a pull request's head. A fork pull request runs without this repository's secrets, so one that changes the image fails at the smoke build's Docker Hub login. A maintainer lands such a contribution on an in-repo branch and opens the pull request from there.

**Workflows reach the hub.** Every workflow here is a thin caller of a hub reusable task, pinned to a hub release commit: the lint gate is `validate-task.yml`, the smoke build and the release are `build-release-task.yml`, and the merge-bot is `merge-bot-task.yml`. A change to a gate or to the build lands in the hub, and it reaches this repo when the pin moves. A publish-time failure inside a hub task is diagnosed from the run log against the pinned hub commit rather than against a file in this repo.

**Dependabot** runs the `github-actions` ecosystem only, once per branch, so `main` and `develop` each receive their own update pull requests. A Dependabot security pull request always targets `main`, and the merge-bot selects the merge method from each pull request's base branch, so it merges either kind. Every Dependabot pull request that originates from this repository auto-merges once its required checks pass, semver-major included, through [`merge-bot-pull-request.yml`](./.github/workflows/merge-bot-pull-request.yml). An action bump is not a shipped input, so it ships in the next scheduled publish rather than on merge.
