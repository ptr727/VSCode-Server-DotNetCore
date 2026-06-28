# Code Style and Formatting Rules

This is the single code-style guide for the repo. The **General** section applies to every file. This repo ships no compiled application source - the Dockerfile is the only build input - so it carries the **General** section only; the per-language sections (.NET, Python) from the upstream template are omitted because nothing in those languages is built here. The carry-whole model still holds for config: [`.editorconfig`](./.editorconfig) keeps its inert `[*.cs]` block so a future re-sync stays a clean overwrite.

Cross-cutting *process* rules (PR titles, branching, US English, markdown style, comments philosophy, workflow YAML, PR review etiquette) live in [AGENTS.md](./AGENTS.md) and are not repeated here.

## General

These rules apply to every file in the repo.

### Tooling Names and Casing

Use each tool's official casing in task labels, docs, and prose - `.NET` (not `.Net`), `Docker`, `actionlint`, `markdownlint`, `cspell`, `Nerdbank.GitVersioning` (NBGV). Don't invent personal variants.

### Verification

This repo compiles nothing, so there is no clean-compile task. The verification gate is the lint set plus the Docker smoke build, and it must report clean before a commit:

- **Markdown** - `markdownlint-cli2` (see [Markdown and Spelling](#markdown-and-spelling)).
- **Spelling** - `cspell` over the user-facing docs.
- **Workflow YAML** - `actionlint` (bundles `shellcheck`) after any `.github/workflows/` edit.
- **Dockerfile** - the CI smoke build (`docker buildx build` for `linux/amd64`) proves the image still builds; CI runs it on every push.

Run the relevant checks after every change; CI runs the same set as the authoritative backstop. Each linter has a known-working Docker image (`davidanson/markdownlint-cli2`, `ghcr.io/streetsidesoftware/cspell`, `rhysd/actionlint`) that auto-discovers its targets, so no local toolchain beyond Docker is needed.

### Lint Diagnostics and Suppressions

- **A new port is not a license to silence diagnostics.** Brownfield / just-ported status never justifies relaxing a linter rule or muting a newly surfaced warning - fix it at the source. (The only brownfield allowance in this template is the one-time git-signing / line-ending migration described in [AGENTS.md](./AGENTS.md), which has nothing to do with linting.)
- **Suppress only genuine false-positives or deliberate, documented exceptions**, always at the **narrowest scope that fits**: an in-line annotation on the specific occurrence over a file-wide disable, and a file-wide disable over a root-config rule change. A root-config relaxation is justified only when the exception genuinely applies repo-wide.
- **Never blanket-disable a batch of rules** to get a file to pass. Rules the shared config deliberately disables (e.g. `markdownlint` `MD013` line-length, `MD033` inline HTML) are **intentional** - do not "fix" them, and do not extend them without cause.

### Markdown and Spelling

These apply repo-wide, in every directory:

1. **Markdown linting**: All `.md` files must be lint-clean (error and warning free) via the VS Code `markdownlint` extension. [`.markdownlint-cli2.jsonc`](./.markdownlint-cli2.jsonc) at the repo root is the single source of truth - the davidanson `markdownlint` extension and a command-line `markdownlint-cli2` run both read it, so the IDE and CLI stay in lock-step. Rules it deliberately disables (e.g. `MD013` line-length, `MD033` inline HTML) are **intentional** - do not "fix" them. Fix violations at the source rather than disabling rules.
2. **Spelling**: All spelling must be clean via the CSpell VS Code integration; words must be correctly spelled in **US English** (the repo-wide convention - see [AGENTS.md](./AGENTS.md)). Project-specific terms go in [`cspell.json`](./cspell.json), the single source shared by the editor and CI - not in a parallel `.code-workspace` word list.
