# Instructions for AI Coding Agents

**VSCode-Server-DotNetCore** is a Docker image of [LinuxServer.io Code-Server](https://github.com/linuxserver/docker-code-server) with the .NET LTS and STS SDKs pre-installed. It ships a single multi-architecture container image to Docker Hub; there is no application source in this repo (the carried `.cs`/.NET style rules are inert - see [Template adaptations](#template-adaptations)). This file is the single source of truth for cross-cutting rules. Code style lives in [`CODESTYLE.md`](./CODESTYLE.md) at the repo root - one guide with a General section that applies to every language plus per-language sections carried whole (inert ones cost nothing).

Treat this file as authoritative for everything else; don't restate its rules elsewhere. A derived repo's **project-specific conventions and public-API/behavioral contracts** also live here, **not** in [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) - that file targets GitHub Copilot / VS Code specifically, while this file is the agent-agnostic one every coding agent is directed to read, so any rule a reviewer must honor has to live here to be provider-independent.

## Git and Commit Rules

- **Default to staging, not committing.** Stage changes with `git add` and leave `git commit` to the developer unless the developer has explicitly authorized the agent to commit for the current ask ("commit this", "open a PR", etc.). Authorization is scope-bound - it covers the commits needed for that specific task, not a blanket commit license for the rest of the session.
- **All commits must be cryptographically signed (SSH or GPG).** Branch protection enforces this on both branches; unsigned commits are rejected on push. Signing depends on environment configuration - `git config commit.gpgsign true`, a configured `user.signingkey`, and a working signing agent (loaded `ssh-agent` for SSH, or `gpg-agent` for GPG). If signing is not configured in the environment, **do not commit** - surface the missing config to the developer and stop at `git add`. Verify before any agent-authored commit (`git config --get commit.gpgsign && ssh-add -L` or the GPG equivalent). **Signing must be live before the *first* commit, not retrofitted.** Turning on `Require signed commits` against a branch that already has unsigned commits forces a rewrite of that entire history to re-sign it - changing every commit SHA and making whoever does the rewrite the committer and signer of every commit (a rebase preserves the `author` field but not the original signatures; you cannot sign another contributor's commits for them). During new-repo setup, never create commits until signing is verified.
- **Never force push.** Do not run `git push --force` or `git push --force-with-lease` under any circumstances. Force pushing rewrites shared history and can cause data loss.
- **Never run destructive git commands** (`git reset --hard`, `git checkout .`, `git restore .`, `git clean -f`) without explicit developer instruction.

## Branching Model

- `develop` is the integration branch. Feature branches -> `develop` is **squash-only**; develop is kept linear.
- `develop` -> `main` is **merge-commit only** (no squash, no rebase). Merge commits preserve develop's commit list as a real second-parent reference on main, which lets the release model attribute releases to the develop commits that produced them (relevant both for the weekly publish and the opt-in `PUBLISH_ON_MERGE` mode - see "Release Model" below). Branch protection enforces this: the develop ruleset allows only `squash`, the main ruleset allows only `merge`.
- All commits on both branches must be cryptographically signed (SSH or GPG). Squash and merge commits created via the GitHub UI are signed by GitHub's web-flow key.
- **`develop` is forward-only - no `main -> develop` back-merges.** The develop ruleset's squash-only setting physically blocks merge commits on develop. Historical back-merge commits that predate this rule must not be repeated.
- **Both rulesets intentionally omit "Require branches to be up to date before merging".** The flag is off on `main` and on `develop`, for related but distinct reasons.
  - *Main:* the check is graph-based - it asks whether main's tip commit is reachable from develop, not whether the two branches have the same content. After any develop -> main release, main's tip is a brand-new merge commit that develop's history doesn't contain. Forward-only develop never adds it (no back-merge of main into develop), so the check would fail on every subsequent release. Other technical workarounds - rebasing develop onto main, or rewriting develop's history - exist but contradict the squash-only develop ruleset and the linearity invariant.
  - *Develop:* the check stalls bot auto-merge when two bot PRs against develop land within the same window. As soon as the first merges, the second flips to `mergeStateStatus: BEHIND` and GitHub's auto-merge will not fire while strict is on. The merge-bot only *enables* auto-merge on `opened`/`reopened` (see below) and never auto-updates bot branches, and Dependabot's rebase isn't real-time, so the second PR sits OPEN with all checks green indefinitely. Squash mechanics still rebase the diff onto develop's tip on merge, `required_linear_history` still enforces linearity, textual conflicts still block `mergeable: CONFLICTING`, and the required `Check pull request workflow status` still gates merges - the only thing lost is pre-merge detection of *semantic-but-not-textual* conflicts, which the post-merge develop CI run catches anyway.
- **Configuring branch protection on a derived repo: don't hand-build the rules.** Reconstructing the rules by hand is error-prone and has gone wrong on past ports. First delete **all** legacy classic branch-protection rules and any stray rulesets (this repo uses rulesets *only*), then create **exactly two rulesets named `develop` and `main`** by exporting the upstream template's two rulesets and re-importing them via `gh api -X POST .../rulesets` (`gh ruleset` is read-only). The names are load-bearing - this file and the workflows reference them. **Brownfield repos** (pre-existing history) need an extra step: `Require signed commits` rejects legacy unsigned commits and the admin bypass does not cover `git push --force`, so re-signing requires temporarily disabling the ruleset.
- **Dependabot targets both `main` and `develop` in parallel.** [`.github/dependabot.yml`](./.github/dependabot.yml) duplicates every ecosystem entry (one per branch), so each branch absorbs its own bot PRs independently, neither falls behind, and the forward-only rule still holds (nothing is back-merged from main to develop - both branches receive their updates directly). The merge-bot ([`.github/workflows/merge-bot-pull-request.yml`](./.github/workflows/merge-bot-pull-request.yml)) dispatches `--squash` or `--merge` from each PR's base ref via a `case` statement so the form matches the ruleset on either base. Dependabot **security** PRs (CVE-driven) always open against the repo default branch (`main`) regardless of `target-branch` - the same `case` statement covers them.
- **Maintainer-pushed commits on a bot PR auto-disable auto-merge.** The merge-bot's merge jobs only fire on `opened` / `reopened` events (auto-merge is enabled exactly once per PR). When a maintainer pushes commits to a bot's branch (a `synchronize` event with an actor that isn't the same bot), the merge-bot's `disable-auto-merge-on-maintainer-push` job fires and calls `gh pr merge --disable-auto`. The maintainer's commits stay in the PR but won't auto-merge with the bot's content; re-enable auto-merge manually (`gh pr merge --auto <PR>` or the GitHub UI) when ready.
- **Why parallel dual-target rather than develop-only with eventual flow-through:** pull-distribution channels (the published Docker Hub image) consume `main` directly. A develop-only model would leave `main` running stale code during long-running develop features.
- **App-token workflows use Client ID, not App ID.** `actions/create-github-app-token` deprecated the numeric `app-id` input in v3.0.0; this repo uses `client-id: ${{ secrets.CODEGEN_APP_CLIENT_ID }}`. When adding new App-token call sites, use the same form - do not reintroduce `app-id` / `CODEGEN_APP_ID`.

## Release Model

This repo uses a **two-phase model by default**: PRs build fast, publishing is batched. The load-bearing rules:

- **PRs smoke-test only.** This repo ships no application source, so there are no unit tests - [`test-pull-request.yml`](./.github/workflows/test-pull-request.yml) runs a `dorny/paths-filter` `changes` job that gates a **reduced** Docker smoke build of only the changed targets (`linux/amd64` only), never pushing. Build-workflow files are intentionally not in the path filters - a filter can't tell a logic change from an action-version bump - so a workflow-only change isn't smoke-built; the reusable workflows are exercised by the next run that uses them (a later code PR's smoke build, or the scheduled/publish run). There is no CI workflow-lint job; lint workflow edits with `actionlint` locally before pushing.
- **Merges don't publish by default.** [`publish-release.yml`](./.github/workflows/publish-release.yml) is the sole publisher: its **weekly schedule** (Mondays 02:00 UTC) and **manual `workflow_dispatch`** always do the full build/publish of **both** `main` and `develop` (a branch matrix). Its `push` trigger publishes only when the **`PUBLISH_ON_MERGE` repository variable** is `true` (opt-in legacy continuous-release). Unset/`false` = two-phase.
- **Required check.** The `changes` job is in the `Check pull request workflow status` aggregator's `needs` and **must succeed** (not just "not fail") - a paths-filter error must never let a target-changing PR merge with its smoke build silently skipped. Skipped smoke jobs (no matching change) pass; `failure`/`cancelled` blocks.
- **Reusable-task parameter contract.** Every `build-*-task.yml` and `build-release-task.yml` takes `ref` (git ref to check out/version), `branch` (logical branch driving config/tags/prerelease - `main` => Release/`latest`/non-prerelease, else Debug/`develop`/prerelease), and where relevant `smoke`. **Branch-derived config keys off `inputs.branch`, never `github.ref_name`** - the publisher's matrix builds `develop` from a run whose `github.ref_name` is `main`, so `ref_name` would be wrong. Artifact names are branch-suffixed so both matrix legs coexist in one run. `get-version-task.yml` takes a `ref` so NBGV versions the right branch.
- **Orchestration vs. build - the override seam.** The pipeline splits into two layers. The **orchestration** layer is generic and meant to be synced verbatim from upstream: [`publish-release.yml`](./.github/workflows/publish-release.yml) (publish plan + branch matrix), the `get-version` + `github-release` jobs inside [`build-release-task.yml`](./.github/workflows/build-release-task.yml), [`get-version-task.yml`](./.github/workflows/get-version-task.yml), [`build-datebadge-task.yml`](./.github/workflows/build-datebadge-task.yml), and the aggregator shape of [`test-pull-request.yml`](./.github/workflows/test-pull-request.yml). Within `test-pull-request.yml`, only the `changes -> smoke-build -> check-workflow-status` aggregator wiring and the ruleset-bound job name are verbatim orchestration; the `dorny/paths-filter` entries are owned/per-target. The **build** layer - the `build-<target>-task.yml` leaf tasks - is what this repo owns and replaces. The contract that keeps the seam clean: **a target contributes files to the GitHub release by uploading a workflow artifact named `release-asset-<branch>-<target>`.** The `github-release` job collects every `release-asset-<branch>-*` artifact by pattern - its `download-artifact` step uses `pattern:`/`merge-multiple:`, **never an `artifact-ids:` that names a build job's output** (the producing build jobs still appear in `needs` for sequencing) - so it (the tag-the-commit + create-the-release + attach-the-assets logic) is reusable **verbatim**. **This name-pattern handoff is canonical for every repo, single-target included** - a target that attaches release files names its asset `release-asset-<branch>-<target>` and the verbatim `github-release` globs it; do not switch to an `artifact-id` output plus `download-artifact` `artifact-ids:`, which looks tidier for 1:1 but forks the `github-release` download (`pattern:`/`merge-multiple:`) and breaks its verbatim carry. **This repo is Docker-only:** its one delivery target is the Docker Hub image push, which contributes **no** `release-asset-*` - so the `github-release` job's `fail_on_unmatched_files` is driven by an `expect_release_assets` input set false here, and the release carries only the source zip, README, and LICENSE while the image goes to Docker Hub.
  - **What a downstream still curates** (this is by design, not a leak): the *list* of leaf jobs in `build-release-task.yml`. You delete the target jobs you don't ship and add the one(s) you do - `build-release-task.yml`'s `github-release` job is untouched, but the file is not byte-identical because its `needs`/job list reflects your targets. Here that list is the single `build-docker` job. Making the list itself target-agnostic is a larger "factor build from orchestration" refactor that is intentionally **not** done.
  - **Image-registry pushes** (Docker Hub): `build-docker-task` pushes multi-arch tags directly; it contributes **no** `release-asset-*`. The image tag is build-layer-owned - drive it from whatever version source fits (NBGV `SemVer2`, an upstream-release pin, or a per-image matrix). To publish the Docker Hub repository overview, [`publish-docker-readme-task.yml`](./.github/workflows/publish-docker-readme-task.yml) pushes this repo's root [`README.md`](./README.md) via `peter-evans/dockerhub-description`, wired into `publish-release.yml` and gated to `main`.
  - `get-version-task.yml` installs the .NET SDK only because NBGV needs the runtime to compute the version/tag - heavyweight but expected; acceptable as-is.
- **No-op republish guarantee.** A weekly/dispatch publish where NBGV `SemVer2` is **unchanged** (no new commit since the last publish) re-pushes **nothing** to GitHub Releases (the `github-release` job's `release-exists` check skips the create step), keyed on the version string. **Docker always re-pushes** by design: it picks up upstream base-image refreshes (e.g. the LinuxServer.io code-server base) that aren't visible in the repo. Boundary: `version.json` has **no `pathFilters`**, so *any* commit - including a CI/workflow-only or docs-only change - advances the NBGV git height and therefore `SemVer2`, and the next publish *does* create a fresh release for it even when the shipped image is otherwise identical. This is accepted NBGV behavior; `pathFilters` are intentionally not added.
- **Versioning is semantic and maintainer-controlled.** The `version` (major.minor) in [`version.json`](./version.json) is the version floor; NBGV appends the git height (the SemVer patch position) for the build version. `main` (the public release ref) builds a stable `X.Y.<height>`; `develop` builds a prerelease `X.Y.<height>-g<sha>`. The maintainer edits `version.json`; dependency bumps, CI/workflow fixes, doc edits, and template re-syncs leave it untouched.
  - **Bump `version.json` only for functional changes, by maintainer instruction.** Raise the major/minor when the work being introduced warrants a new semantic version - a new feature, a behavior change, a breaking change - and do it in the PR that introduces that work (typically on `develop`). Do **not** bump on a fixed cadence or mechanically after a release. NBGV advances the patch (git height) on every commit automatically, so a release always gets a fresh build version without any `version.json` edit.
  - **No post-release bump; no develop-ahead requirement.** NBGV advances the patch (git height) on every commit, so a release always gets a fresh build version with no `version.json` edit and there is no `bump-version-X.Y` PR after a release. A `develop -> main` promotion carries whatever `version.json` is current: a promotion with a functional bump releases that new version on `main`; a maintenance-only promotion carries the unchanged `version.json` and `main` advances only its NBGV height.

## Pull Request Title and Commit Message Conventions

### Format

- Imperative subject summarizing the change, <=72 characters, no trailing period. ("Add 24-hour PM2.5 average sensor", not "Added X" or "Adds X".)
- Optional body, blank-line separated, explaining *why* the change is being made when that's non-obvious. The diff shows *what*.

### Rules

- Don't write `update stuff`, `wip`, or other vague titles. (Dependabot's default `Bump X from Y to Z` titles are fine - keep them.)
- Don't add `Co-Authored-By:` lines unless the developer explicitly asks.
- Don't put release-bump magnitude in the title - no "minor", "patch", "release v0.2.0", etc. Nerdbank.GitVersioning computes the next release version from `version.json` + git history. Dependency versions in dependency-bump titles are fine and expected.
- Use US English spelling and match the existing heading style of the file you're editing: title case with lowercase short bind words (a, an, the, and, but, or, of, in, on, at, to, by, for, from); hyphenated compounds capitalize both parts unless the second is a short preposition (*Built-in*, *EPA-Corrected*, *24-Hour*).

### Examples

```text
Add structured logging extensions to library
Pin softprops/action-gh-release to commit SHA
Drop net8.0 multi-targeting from console project
Bump xunit.v3 from 3.2.2 to 3.3.0
Clarify devcontainer setup steps in README
```

## Documentation Style Conventions

### Markdown

- Use reference-style links for any URL referenced more than once or appearing in lists; alphabetize the reference definitions block.
- Inline single-use relative links (e.g. `[CODESTYLE.md](./CODESTYLE.md)`) are fine.
- One logical paragraph per line; no hard-wrap line-length limit. For an intentional hard line break within a block - stacked badges, status, or license lines - end the line with a trailing backslash (`\`); this explicit form is preferred over trailing whitespace and is not treated as a paragraph split.
- Headings follow the title-case-with-short-bind-words rule from the PR-title section.
- **Write docs in the current state, not as a change from a prior one.** The reader has no memory of the previous behavior, so describe what *is*: "X does Y", never "X *now* does Y", "X *no longer* does Z", "changed/switched/restored to Y", or "X *still* does W". Before/after framing belongs in changelogs, commit messages, and PR descriptions - where the prior state is the point - not in `README.md` or other living docs.

### Comments

Applies to code and workflow (`#`) comments alike.

- Comment only when the code does not explain itself or the logic is genuinely complex. Self-evident code needs no comment.
- Write for the human reading *this* project's code now: state only the non-obvious *why*. No cross-project references (do not name other repos), no historic or design narrative, no rule citations - governance lives in this file, not echoed inline.
- **Keep it short. One line is the default; a comment earns a second line only by carrying a constraint the code cannot.** Most comments are one sentence. Don't restate *what* the code does - a well-named symbol already says it.
- **Do not grow a comment across edits.** When you touch code near an existing comment, the comment must come out **same length or shorter** - never append "one more clause" of rationale. If a block comment has crept to multiple sentences of prose, cut it back to its single load-bearing point as part of your change. Verbosity creep is the specific regression to prevent: every iteration that adds a clause is a regression, not an improvement.
- Match the surrounding code's line length (typically ~120), not an 80-column wrap.

### Character Set

- **Write ASCII in all agent-authored text** - documentation, code, comments, commit messages, and PR descriptions. The agent does not introduce non-ASCII characters. Replace typographic Unicode with its ASCII equivalent on sight:
  - em dash (U+2014) and en dash (U+2013) -> hyphen `-` (use a spaced ` - ` for an em-dash-style clause break)
  - right arrow (U+2192) -> `->`; double arrow (U+21D2) -> `=>`
  - less-than-or-equal (U+2264) -> `<=`; greater-than-or-equal (U+2265) -> `>=`
  - curly quotes (U+2018/U+2019/U+201C/U+201D) -> straight `'` and `"`; ellipsis (U+2026) -> `...`
- **Allowed non-ASCII (two narrow exceptions):**
  - **Scientific or technical symbols with no clean ASCII equivalent** - e.g. ohm, micro, degree, pi. Keep the symbol; do not approximate it away.
  - **Unicode the developer deliberately typed** - emoji used for emphasis or as callout markers (for example the warning/info markers a maintainer placed in `README.md`). Preserve it; never strip the developer's own characters. This carve-out is for developer-authored text, not a license for the agent to add emoji.

### Line Endings

- **[`.editorconfig`](./.editorconfig) defines the correct line ending per file type:** **CRLF** for `.md`, `.cs`, XML/`.csproj`/`.props`/`.targets`, `.yml`/`.yaml`, `.json`, and `.cmd`/`.bat`/`.ps1`; **LF** for `.sh`. `.gitattributes` is `* -text`, so git stores the exact bytes you commit and will **not** normalize endings for you.
- **Choosing an ending for a new file type:** CRLF is the **default** - cross-platform editors on Windows produce it, and it is harmless on Linux for everything except shell. Use LF only when the type **requires** it or CRLF **breaks how it is consumed**: executable scripts/shebangs (`*.sh`, s6, husky), Dockerfiles (CRLF breaks `RUN` heredocs/continuations), and tool-owned formats with a native LF ending (KiCad). **YAML stays CRLF** - GitHub Actions' parser tolerates it and these repos run it without breakage (a repo that also runs yamllint sets `new-lines: disable` to defer to `.editorconfig`). Distinguish where a file is *consumed* from where it is *edited*: consumption on Linux alone does not force LF.
- **Scripts and extensionless executables must be LF - and pinned in `.gitattributes`, not just configured.** A CRLF shebang (`#!/usr/bin/env bash\r`) breaks execution. `.editorconfig` sets `[*.sh] = lf`, but that extension-based rule does not match **extensionless** executables (s6 service scripts `run`/`up`/`finish`, husky/git hook scripts like `.husky/pre-commit`), and `* -text` enforces nothing - so a broad normalization pass or an editor can silently flip them to CRLF (it has). `.gitattributes` is the enforcement layer: it carries `*.sh text eol=lf`, and any repo whose tooling ships extensionless scripts **adds the matching path pin** - e.g. `Docker/s6-overlay/** text eol=lf` for s6 init, `.husky/pre-commit text eol=lf` for husky hooks - so git holds them at LF on checkout and `--renormalize`. This pin is mandatory for any repo that overrides s6 init, uses husky/git hooks, or otherwise ships executable scripts. The same explicit-pin rule extends to **tool-owned file formats the base config doesn't key on**: pin them to whatever ending the tool reads and writes so a normalization sweep can't churn them - e.g. KiCad project/footprint/3D files (`*.kicad_mod`, `*.kicad_sym`, `*.step`), which KiCad writes LF (`*.kicad_mod text eol=lf`, ...). The principle is general: a file class the `.editorconfig` extension rules and `* -text` don't cover needs an explicit `.gitattributes` pin matching its tool's native ending.
- **New files:** create them with the `.editorconfig`-mandated ending.
- **Editing an existing file:** **preserve the file's current line endings** - do not reflow them as a side effect of a content change, even if the file is already non-compliant. A tool that rewrites a file in text mode (a script, a bulk find/replace) can silently flip CRLF to LF and turn a one-line change into a whole-file diff. After any programmatic edit, verify before staging: `git diff --stat` should touch only the lines you changed, and `file <path>` should report the file's expected ending. If a diff balloons to the whole file, you flipped the endings - restore them and re-stage.
- **Fixing a non-compliant file:** bring it to its `.editorconfig` ending as a **deliberate** change, and prefer to isolate it in its own EOL-only commit so the churn is reviewable. When a broader maintenance change has to normalize endings alongside content edits (a repo-wide cleanup sometimes does), call it out explicitly in the commit/PR description and verify the content separately with `git diff --ignore-cr-at-eol`.
- **Derived repos must carry both files.** [`.editorconfig`](./.editorconfig) **and** [`.gitattributes`](./.gitattributes) are mandatory carries. A derived repo missing either file, or one whose `.editorconfig` sets `end_of_line` only under `[*.md]` instead of carrying the full per-extension rules, will accumulate files mixed between LF and CRLF - the exact failure these two files prevent. Carry both files **whole** (the `[*.cs]` block is inert without `.cs` files), including the `*.sh text eol=lf` pin and any extensionless-script path pins. Adopting `.gitattributes` for the first time requires a one-time normalization pass.

### Quantitative Claims

- Any quantitative claim in `README.md` (counts, sizes, version floors, supported platforms) must be verified against current code. If a doc number is derived from a code constant, mark the dependency in a source-code comment so the next editor knows to update both.

## PR Review Etiquette

> **Mandatory in every derived repo.** This entire "PR Review Etiquette" section is the provider-agnostic review-loop *contract* and must be carried **verbatim** into every repo derived from this template, alongside the [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) "GitHub Copilot Review Runbook" that implements it. Without both in-repo, an agent working in the derived repo has no pointer to the reliable Copilot mechanics and falls back to ad-hoc (and known-broken) behavior.

The repo runs a review loop on every PR: local agent iteration plus remote automated review (GitHub Copilot is the configured reviewer). Treat this as a contract regardless of which local agent authored the changes.

### Merge Gate (read this first)

**Do not merge - and do not enable auto-merge - unless ALL of these hold:**

1. Required status checks are green (`mergeStateStatus: CLEAN`), **and**
2. A Copilot review is confirmed on the **current head SHA** (not an earlier push), **and**
3. **Every** Copilot finding on that head SHA is closed out - all review threads resolved, **and** any issue-level Copilot comments (which have no resolve action) triaged and replied to - so zero outstanding findings remain, **and**
4. The maintainer has given **explicit** permission to merge.

`mergeStateStatus: CLEAN` reflects **only** required statuses - it never reflects open bot review comments, so `CLEAN` alone is **never** sufficient to merge. A green/`CLEAN` PR with an unresolved Copilot finding fails this gate; treat it as "not mergeable" no matter what the merge-state field says. The agent never merges on its own (consistent with "default to staging"; merging is maintainer-authorized).

**Merging is not releasing.** A merge to a release branch does **not** by itself publish; publishing is a separate, explicitly configured step in the repo's release pipeline (e.g. a scheduled run, a manual dispatch, or an opted-in publish-on-merge trigger), not an automatic consequence of merging. Never describe a merge as cutting a release, and never trigger a publish without explicit maintainer instruction.

### Expected Review Loop

1. Push changes to the PR branch.
2. Re-request a review for the **current head SHA**. Auto-trigger is unreliable, so request it explicitly via the `requestReviews` GraphQL mutation (now reliable end-to-end - see the runbook); the UI is only a fallback.
3. Wait for review activity on that head. A completed review that raises **no findings** is a valid terminal outcome for that head - proceed; do not re-trigger it or treat the absence of comments as a missing review.
4. Triage findings.
5. Apply fixes or write a rationale for declines.
6. Reply to each thread and resolve what was addressed.
7. Re-run the loop after every fix push until no actionable findings remain.

Drive the loop to green - review confirmed on the latest head SHA and every actionable finding closed - then stop and apply the **Merge Gate** above: all four preconditions must hold, and `mergeStateStatus: CLEAN` alone never satisfies it.

For provider-specific mechanics (how to request review, query review state, post replies, resolve threads), see the **GitHub Copilot Review Runbook** in [.github/copilot-instructions.md](./.github/copilot-instructions.md). This file owns the contract; that file owns the mechanics.

### Triaging Review Comments

For each comment, classify before responding:

- **Bug** - wrong behavior, missing test coverage, or a real divergence between code and docs. Fix it. Reply with the fixing commit SHA when done.
- **Style/convention** - the comment cites a rule from this file or a language-specific style guide. Two cases:
  - The cited rule matches what the existing codebase already does -> fix the offending code.
  - The cited rule contradicts what's in the tree, or industry norm -> **update the rule instead of the code**. The rule is wrong, not the code. Bouncing the same code across rounds is the symptom of a wrong rule. Heuristic: three rounds on the same style category means the rule needs adjusting and the user should authorize the rule change.
- **Architectural opinion** - the comment proposes a different design ("constrain this to disabled-by-default", "move it elsewhere", "add a runtime guardrail"). This is judgment, not a bug. Surface it to the user with a recommendation; don't apply unilaterally.

### Responding and Resolution Expectations

Reply inline with either the fixing commit SHA (for accepted issues) or a concise rationale (for declines). Resolve review threads when addressed or intentionally declined with rationale. Issue-level comments (those at `repos/.../issues/<N>/comments` rather than tied to a specific line) have no resolution action - acknowledge with a reply if needed and move on.

After the final push on a PR, sweep older threads from earlier rounds whose code paths no longer exist; otherwise stale unresolved markers remain in the review UI.

### Escalating to the User

Bring the user in when:

- **Genuine design trade-off** surfaces (fail-open vs fail-closed, narrow vs broad refactor scope, "should we add a guardrail or trust the docstring"). Triage, recommend, ask.
- **Repeated friction** across rounds without convergence - that's the rule-needs-updating signal. Stop, summarize the pattern, and let the user authorize the rule change.
- **Architectural redesign** is requested rather than a bug fix. Surface with a recommendation; never apply unilaterally.

Anti-pattern: don't keep flipping the code on the same style point. Flip the rule once and stick to the rule.

## Workflow YAML Conventions

These conventions describe the target state. New and modified workflows must respect them; the rest of the repo is expected to be brought up to the same standard. Sweep PRs that apply a rule everywhere are welcome when a rule changes.

- **Action pinning**: pin **every** action - first-party (`actions/*`) and third-party - to a commit SHA with a trailing `# vX.Y.Z` comment, so Renovate / Dependabot can still bump it but a tag swap can't change the executed code. Use `# vX` (major-only) only when the upstream's floating major tag doesn't correspond to a specific patch/minor release SHA - pinning to the floating-tag SHA still gives the SHA guarantee, the version comment just records the major line. Documented exception (no SHA pin at all): [`dotnet/nbgv`](./.github/workflows/get-version-task.yml) is consumed via `@master` because the upstream tag stream lags `master` substantially and Dependabot's tag-tracking would propose a downgrade. **This applies to repo-owned build-layer leaves too** - a leaf owning its build specifics is not a reason to use floating tags; Dependabot still bumps SHA pins (updating the SHA + version comment).
- **Filename**: reusable workflows (those with `on: workflow_call`) end in `-task.yml`. Entry-point workflows (`on: push` / `pull_request` / `schedule` / `workflow_dispatch`) do NOT use the `-task` suffix; they end with what they do - `-pull-request.yml`, `-release.yml`, etc. The suffix carries semantic meaning: a `-task.yml` file is meant to be `uses:`-d, never triggered directly.
- **Workflow `name:`** (the top-level `name:` field): reusable workflow names end in **"task"** (e.g. `Build Docker image task`); entry-point workflow names end in **"action"** (e.g. `Publish project release action`, `Test pull request action`). The displayed action name in the GitHub Actions UI tells you at a glance whether you're looking at an orchestrator or a callee.
- **Job and step `name:` suffixes**: every job's `name:` ends in **"job"**; every step's `name:` ends in **"step"**. **Exception**: a job whose `name:` is also referenced as a required-status-check `context:` in a branch ruleset (currently `Check pull request workflow status` in `test-pull-request.yml`) keeps the ruleset-bound name verbatim - renaming would silently break required-status-check enforcement. Do not "fix" that name; if a future job becomes ruleset-bound, mark it the same way.
- **Concurrency**: top-level workflows declare `concurrency: { group: '${{ github.workflow }}-${{ github.ref }}', cancel-in-progress: true }` so a fresh push supersedes an in-flight run on the same ref. **Documented exceptions** (both record the rationale inline in their header comment): (1) [`merge-bot-pull-request.yml`](./.github/workflows/merge-bot-pull-request.yml) uses `cancel-in-progress: false` because its event model (enable-auto-merge on opened, disable-auto-merge on maintainer-pushed synchronize, with method dispatched by base) requires each event to run to completion in arrival order - cancellation would leave auto-merge in an inconsistent state. (2) [`publish-release.yml`](./.github/workflows/publish-release.yml) uses both a **global, ref-independent group** (`group: ${{ github.workflow }}`, dropping the usual `-${{ github.ref }}`) and `cancel-in-progress: false`. It publishes shared ref-independent artifacts (both branches' Docker tags/caches and GitHub releases) on schedule/dispatch regardless of the triggering ref, so a ref-scoped group would let a scheduled run (ref `main`) and a manual dispatch (ref `develop`) run concurrently and double-push; and cancelling a publish mid-flight can leave a partially pushed tag set or a half-created release. The global group + queueing serializes every publish run to completion.
- **Shells**: multi-line `run:` blocks with bash start with `set -euo pipefail` - fail fast, fail on undefined vars, fail on a failed pipe segment.
- **Conditionals**: multi-line `if:` uses folded scalar `if: >-` so YAML preserves whitespace correctly. Literal block (`if: |`) is wrong because it embeds newlines inside the boolean expression.
- **Boolean inputs**: workflows triggered both via `workflow_call` and `workflow_dispatch` must declare each boolean input in *both* trigger blocks - one definition does not propagate to the other. `workflow_call` delivers booleans as actual booleans; `workflow_dispatch` delivers them as the *strings* `"true"`/`"false"`. Any `if:` consuming a boolean input must compare against both forms - `if: ${{ inputs.foo == true || inputs.foo == 'true' }}`.
- **Reusable workflows**: job-level `permissions:` are validated *before* the `if:` evaluates, so even a skipped job needs valid permissions declared. A `release` job with `permissions: contents: write` and `if: ${{ inputs.publish }}` will still cause `startup_failure` on a caller that doesn't grant `contents: write`. Either declare permissions at the call site, or omit the inner block and inherit.
- **Allowlist `success` and `skipped` explicitly** when chaining jobs across optional dependencies - `!= 'failure'` lets `cancelled` through (timeout, runner failure, manual cancel). Use `(needs.X.result == 'success' || needs.X.result == 'skipped')`.
- **Artifact retention**: workflow artifacts are an intra-run handoff only - durable copies live on the GitHub release, not in workflow artifacts - so they must not survive the run and accumulate against the small account-wide artifact-storage quota. **Every workflow that can produce artifacts ends with a terminal `cleanup-artifacts` job** that deletes the run's artifacts via the REST API: `permissions: actions: write`, `needs` the artifact producers, an `if:` that **includes** `always()` (so a failed run still cleans up) plus any workflow-specific gate (e.g. `publish-release.yml` adds `&& needs.setup.outputs.publish == 'true'` to run only on real publishes), independent of any required status check so housekeeping never gates a merge, `continue-on-error: true` on the delete step so even an unexpected failure never reds the run, and tolerant of individual list/delete failures (warn and continue). This covers not just `actions/upload-artifact` but build-records that actions emit automatically (e.g. `docker/build-push-action`'s `.dockerbuild`). Both `publish-release.yml` and `test-pull-request.yml` carry one; add one to any new artifact-producing entry workflow. Set `retention-days: 1` on explicit uploads as a backstop.
- **Docker layer cache**: cache to/from a registry tag (`type=registry`, e.g. `buildcache-<branch>` on Docker Hub), not the GitHub Actions cache (`type=gha`), to keep large image layers off the 10 GB Actions cache. A **multi-image** repo uses a **per-image** buildcache tag (`<repo>:buildcache-<branch>` for each image, plus the base image's own tag and inline cache); it does not fall back to `type=gha` for the extra images.
- **Tag pinning on releases**: when using `softprops/action-gh-release` (or any tag-creating action), pass `target_commitish` explicitly - without it, GitHub's REST API defaults the new tag to the repository's default branch instead of the commit that built the artifact. Pin it to the **exact built commit's SHA** (the publisher uses NBGV's `GitCommitId` output), not `github.sha` (wrong branch in the publisher's branch matrix - a `develop` leg runs with `github.sha` = main's tip) and not a branch name (a moving ref that a mid-run commit could advance past the built tree).

### Running the Linters Locally (Known-Working Invocations)

There is no CI lint job for workflow YAML or Markdown - the gate is local, so an agent must know how to actually run these tools. Some linters are not obvious to invoke and their non-Docker install paths (curl-pipe installers, global npm) are frequently blocked in sandboxes or fail on WSL. **Prefer the Docker invocations below; they are the known-working path and need no local toolchain.** Both tools auto-discover their targets from the working directory.

- **actionlint** (GitHub Actions workflow YAML - run after any `.github/workflows/` edit, since workflow-only changes are not smoke-built):

  ```sh
  docker run --rm -v "$PWD":/repo --workdir /repo rhysd/actionlint:latest -color
  ```

  The `rhysd/actionlint` image bundles `shellcheck`, so it also validates `run:` shell blocks. The direct-binary/curl-installer path is often sandbox-blocked - use Docker.

- **markdownlint-cli2** (Markdown - mirrors the davidanson VS Code extension via the shared [`.markdownlint-cli2.jsonc`](./.markdownlint-cli2.jsonc), so the CLI and IDE agree):

  ```sh
  docker run --rm -v "$PWD":/workdir davidanson/markdownlint-cli2:latest "**/*.md"
  ```

  In a configured editor the davidanson extension is enough; use the Docker CLI when there's no IDE (agent/headless) or to confirm a clean run before pushing.

When pulling a public image fails on a Docker-Desktop/WSL credential-helper error (`docker-credential-desktop.exe: exec format error`), retry with an empty Docker config: `DOCKER_CONFIG=$(mktemp -d) docker run ...` after writing `{}` to `$DOCKER_CONFIG/config.json`.

## Template adaptations

Repo-specific deviations from the [ProjectTemplate](https://github.com/ptr727/ProjectTemplate) baseline, with rationale:

- **No application source.** This repo builds a Docker image only; it ships no `.cs` (or any other language) source. The .NET section in [`CODESTYLE.md`](./CODESTYLE.md) and the `[*.cs]` / ReSharper block in [`.editorconfig`](./.editorconfig) are carried whole per the all-files rule but are **inert** here, and there is no `.vscode/` .NET task group. They are kept so a future re-sync stays a clean whole-file overwrite.
- **Docker is the only delivery target.** The release pipeline keeps only the Docker leg. [`build-release-task.yml`](./.github/workflows/build-release-task.yml) drops the NuGet, PyPI, and executable jobs and their `github-release` `needs` entries; [`publish-release.yml`](./.github/workflows/publish-release.yml) drops the `publish-pypi` job; [`test-pull-request.yml`](./.github/workflows/test-pull-request.yml) keeps only the `docker` path filter and drops the .NET `unit-test` job. The `github-release` job relaxes `fail_on_unmatched_files` because a Docker-only repo attaches no `release-asset-*` files (the image is pushed to Docker Hub; the release carries only the source zip, README, and LICENSE).
- **Dockerfile builds from an upstream base image, not from local source.** The image installs the .NET SDKs into the LinuxServer.io code-server base via `dotnet-install.sh`, so [`build-docker-task.yml`](./.github/workflows/build-docker-task.yml) passes only `LABEL_VERSION` as a build arg - the template's source-build args (`BUILD_CONFIGURATION`, `BUILD_VERSION`, etc.) do not apply. The Dockerfile lives at the repo root (`./Dockerfile`), not under `Docker/`.
- **Docker build/lint commands** (no clean-compile task exists for this repo): build with `docker buildx build --platform linux/amd64,linux/arm64 --tag testing:latest .`; smoke-test a single arch with `docker buildx build --load --platform linux/amd64 --tag testing:latest .`. Markdown is linted per [`CODESTYLE.md`](./CODESTYLE.md) "Markdown and Spelling"; workflow YAML with `actionlint`.
