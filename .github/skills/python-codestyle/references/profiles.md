# Python Profile Details

## Adapt before propagating

The rules in `SKILL.md` describe the default Python profile: a package that publishes to PyPI,
type-checked by pyright in strict mode, dependencies in `[dependency-groups]`. A derived repo
often differs, and when it does, adapt these fields to match the repo's actual toolchain rather
than copying verbatim (a verbatim copy that misdescribes the repo is inaccurate and gets rejected
in review). The axes that commonly vary per repo:

- **Type checker in CI**: pyright strict, mypy with its strict flags (run in CI and the editor, with
  pyright kept editor-only through Pylance), or both. A repo running both runs pyright itself,
  per `SKILL.md` "Toolchain". The clean-compile runs every checker CI runs.
- **Dependency declaration**: the uv form declares the dev tools CI runs in the `dev` group of
  `[dependency-groups]`, the one group a plain local `uv sync` or `uv run` installs, and which CI's
  `uv sync --all-groups --frozen` installs too, since it takes every group and no extra. PEP 621
  `[project.optional-dependencies]` (installed with `uv sync --extra <group>`) suits only a tool CI
  does not run. The pip form declares its dependencies in `requirements*.txt` files, installed
  together in one resolve, per `SKILL.md` "Local development loop".
- **Versioning / publishing**: a published package (`_version.py` plus a version source,
  `uv build`, and a PyPI publish step), or a source-only repo with a static `version` and no
  publish step (see Versioning below).
- **VS Code config home**: editor settings/extensions may live in `.vscode/*.json` or the
  `<Repo>.code-workspace`, while tasks/launch/debug configs can only be external `.vscode/*.json`
  (they cannot live in the workspace file). The repo's own `tasks.json` sits wherever it keeps it,
  and the canonical task definitions it is written against are the hub `vscode-tasks-python.json`
  snippet, which resolves the same way from every repo.

## Two profiles: full specification

A repo's Python is one of two shapes, declared as the `build` or `lint-only` profile and validated
against the directory's structural shape. Most of the `SKILL.md` rules (src layout, pytest coverage)
describe the Project shape (the `build` profile), and its uv project, `uv.lock`, and `uv run` rules
describe that shape's uv form. The two differ by trait, whether the Python has third-party runtime
dependencies or is the repo's deliverable. The fleet's audit reads the shape that trait leaves
rather than inspecting imports. A `[project]` or `[build-system]` table in `pyproject.toml`, a
committed `uv.lock`, or a `requirements*.txt` beside it marks the build profile, and tool
configuration alone marks the lint-only one:

- **Project** (the `build` profile): the Python has third-party runtime dependencies, or is the
  repo's deliverable. It takes one of two forms. The uv form is a PEP 621 project: `[project]`
  with `dependencies` (dev tools in `[dependency-groups]`, per the dependency-declaration axis
  above), a `[build-system]`, and a committed `uv.lock` (pinned LF, per GOVERNANCE.md's "Line
  Endings" section). CI runs `uv sync --all-groups --frozen` + `uv run <tool>`, so the lockfile pins
  tool versions. That sync installs every `[dependency-groups]` group and no
  `[project.optional-dependencies]` extra. The pip form is a `pyproject.toml` beside a
  `requirements*.txt`, installed with pip, whether or not it carries a `[project]` table. A
  committed `uv.lock` makes a directory the uv form even where a `requirements*.txt` sits beside it.
  In the pip form CI builds the environment as `SKILL.md` "Local development loop" shows, runs
  pytest from it as `.venv/bin/python -m pytest`, and runs ruff through `uvx`. In a directory
  declared in the hub validator's `python-directories` input it runs the type checker through
  `uvx` pointed at that environment, or runs mypy from the environment where it is installed
  there, while the undeclared default root runs a bare `uvx <checker>@latest` with nothing
  installed.
- **Scripts** (the `lint-only` profile): stdlib-only utility scripts embedded in a non-Python repo
  (e.g. a Python tooling subtree of a `csharp` app). Run the tools with `uvx` (no project install,
  no lockfile): the `pyproject.toml` carries only tool config (`[tool.ruff]`, `[tool.mypy]`, and
  an optional `[tool.pyright]` editor block), with no `[project]`, no `[build-system]`, and no
  `uv.lock` (that metadata would misrepresent it as a shippable package). mypy is the type-check
  gate (there is no first-party package for pyright strict to anchor on), and a `[tool.pyright]`
  block in standard mode keeps Pylance quiet in the editor, the same mypy-gate/pyright-editor
  split the build profile uses. There is no lockfile, and a `uvx <tool>@<ver>` pin in a `run:`
  step is not something Dependabot tracks, so CI runs `uvx ruff@latest` / `uvx mypy@latest` rather
  than a manual pin that would silently go stale. The fleet rule is to pin only what Dependabot
  auto-updates (SHA-pinned actions, package deps) and otherwise run latest, so the VS Code tasks,
  README, and CI all run the unpinned latest here. `.py` files follow the repo's LF line-ending
  default (per GOVERNANCE.md's "Line Endings" section). There is no pytest suite, and `unittest` is
  the runner instead. The directory still owes tests, written with the standard
  library's `unittest` so they run under bare `python3` with nothing installed, as
  `test_<script>.py` under a `tests/` directory beside the scripts it exercises and their
  `pyproject.toml` (`<scripts-dir>/tests/`), where the validator looks for it, kept apart so a
  test never reads as a tool. Within the scripts directory the name carries the kind: a gate
  that checks and exits non-zero on a finding takes a `_lint` or `_gate` suffix, and a utility
  that does work takes none. Any repo carrying Python
  owes the same gates whatever its profile: lint, format, a type check, a test suite, and a
  coverage report to Codecov. The hub validator runs them in each directory the caller declares
  in its `python-directories` input, which the registry's `pythonDirectories` mirrors. From inside
  a lint-only directory it runs `uvx ruff@latest check`, `uvx ruff@latest format --check`,
  `uvx mypy@latest`, and `uvx coverage@latest run -m unittest discover -s tests`, then writes
  `coverage.xml` and uploads it best-effort per `WORKFLOW.md` D1.6, with no threshold adopted. A
  declared directory with no `tests/` fails that job.

## Versioning

**Published packages.** `_version.py` ships with `__version__ = "0.0.0"` as a placeholder. Until
you wire `_version.py` to something that increments (the usual options are `hatch-vcs`, a
version.json bridge, or manual bumps), no new PyPI versions will land, and publishing with
`skip-existing: true` keeps a stuck placeholder version from failing the run.

**Source-only repos** (no PyPI publish, with a source-release on dispatch or no release at all) do
not need `_version.py`: keep a static `version` in `pyproject.toml` `[project]`, or let the
release pipeline's version source (e.g. NBGV plus `version.json`) own the tag. There is no publish
step to guard, so `skip-existing` does not apply.
