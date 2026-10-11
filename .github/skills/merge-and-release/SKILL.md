---
name: merge-and-release
description: >-
  Merges a ready develop -> main promotion PR for any ptr727/ProjectTemplate fleet repo and, when
  asked, dispatches the release, in this hub always refreshing this machine's installed Skills
  from the newly promoted content as part of that release step, never as a separate ask. Use this
  whenever asked to merge main, ship a release, cut a release, or finish a promotion once its PR
  is already green and fully resolved (produced by drive-pr or by hand). When the request does not
  say how far ("merge main", "ship it"), ask once whether to merge only or merge and release,
  rather than guessing which the maintainer wants this time. Triggers even when the phrasing is as
  short as "merge main and release", because that already states the scope and is itself the
  explicit, current go-ahead this skill acts on without asking again, though it never substitutes
  for the pr-review-conduct Merge Gate, a promotion PR that is not actually green and fully
  resolved gets reported and stopped on, not merged. Where a merge or dispatch is actually
  performed this skill wins over `branching-and-release-model`, which supplies the policy it
  follows, and an `unattended-handoff` run invoked with scope main or release is the one standing
  go-ahead it accepts in place of asking.
---

# Merge and Release

## Why This Exists

Once drive-pr (or a maintainer by hand) leaves a promotion PR ready, the same two steps follow
every time: merge it, and usually dispatch the release it unblocks. In this hub a promotion can
also change `.agents/skills` content this very session depends on, so the release step always
carries a Skills refresh with it there, never a separate branch to ask about, an ambiguous "merge
and release" on the hub must not leave the maintainer unsure whether Skills got refreshed. One
skill covers all of it, scoped down by what the maintainer actually asks for.

## How Far to Go

- Read the invocation for an explicit scope first. "Just merge" or "merge only" means stop after
  the merge. "Merge and release", "ship it", or "cut a release" means also dispatch, and in this
  hub also refresh Skills as part of that same step. Act on either without asking.
- When the request names no scope ("merge main"), ask once, before merging: merge only, or merge
  and release. Recommend "merge and release" as the default on a release-model repo, a promotion
  merged without its release is the more common regret there. Recommend "merge only" as the
  default on an operational repo (registry `workflowModel: operational`), where a release is a
  separate, deliberate dispatch rather than an automatic follow-on to a promotion, per
  branching-and-release-model's "Operational repositories" delta.
- Detect the hub automatically, `git remote get-url origin` or `gh repo view --json
  nameWithOwner` naming `ptr727/ProjectTemplate`. There the release scope silently includes the
  Skills refresh, a downstream repo never sees it, it has no `.agents/skills` of its own to
  refresh.

## What Invoking This Skill Authorizes

- Naming this skill, and answering its how-far question, is the maintainer's explicit, current
  go-ahead to merge the promotion PR and to perform the scope chosen, for the one repo and PR in
  front of the agent. It is never a standing mode carried to the next PR.
- The one standing grant is an `unattended-handoff` run the maintainer invoked with scope `main`
  or `release`, which names in advance each promotion that run's workers make, in that session
  only. A worker handing a promotion here under it asks no how-far question, since the scope
  states it, and the Merge Gate is still re-verified per promotion.
- It is never permission to merge a PR that fails the Merge Gate. Re-verify the gate at
  invocation time, a check from earlier in the session can be stale.

## The Procedure

1. Identify the open develop -> main promotion PR for this repo, stop and report if none is open.
2. Record the promotion's live head, `gh pr view [number] --repo owner/repo --json headRefOid
   --jq .headRefOid`. Then, from a hub checkout, `scripts/` is not carried into downstream repos,
   run `scripts/pr_review.py status [number] --repo owner/repo` on it and confirm the
   pr-review-conduct Merge Gate. Stop and report exactly what is missing rather than merging on a
   partial gate. A `status` exit `45` is not a partial gate where the promotion meets the one case
   that skill's Merge Gate item 2 states. Check that case again on every re-run below, and record
   its evidence for the head step 3 merges, as that item says.
   Confirm the digest's `head=` is a prefix of the recorded SHA, re-running both where it is not,
   so the SHA step 3 merges is the one the gate verified. Where drive-pr's ready report named a
   head and it is not a prefix of the recorded one, stop and re-ask with the commits added,
   `gh api repos/owner/repo/compare/<reported>...<recorded> --jq '.commits[] | .sha[:8] + " " +
   (.commit.message | split("\n")[0])'`, since a feature PR squashed into `develop` after the
   report moves the promotion's head onto content the maintainer never saw. Under an
   `unattended-handoff` standing grant this comparison is skipped, even where the worker holds a
   ready report. Content another session merged meanwhile rides along, as that skill's grant
   accepts.
   Where no report named a head, a promotion made ready by hand, the go-ahead covers the head
   this step recorded.
3. `gh pr merge [number] --merge --match-head-commit <sha> --repo owner/repo`, where `<sha>` is
   the head the go-ahead covers. Attended, that is the head `drive-pr`'s ready report named, or
   the moved head the maintainer approved after step 2's re-ask. Under an `unattended-handoff`
   grant, or where no report named a head, it is the head step 2 recorded. The server then
   refuses the merge if the head moved past that SHA. Never `--delete-branch`, the promotion
   PR's head is `develop`.
4. Confirm the merge landed, `mergedAt` set, `main`'s tip matching the merge commit.
5. When the chosen scope includes a release, first bring the hub checkout used for this procedure
   current, `git fetch origin main`, and read this repo's `releaseTrigger` from that fetched tip
   rather than a possibly-stale working tree copy, relevant when the target repo is the hub itself
   and this exact promotion changed its own registry entry. Select the one matching entry
   explicitly, falling back to the registry's own default when that entry sets no
   `releaseTrigger` of its own, and stop and report rather than guessing when selection is not
   exactly one match, on a non-1 count exit non-zero rather than returning empty with success, an
   ambiguous or missing match must fail loud, not read as an empty value still safe to act on: `git
   show origin/main:registry/repos.json | jq -r --arg name '<repo-name>' '(.repos | map(select(.name
   == $name))) as $m | if ($m | length) == 1 then ($m[0].releaseTrigger // .defaults.releaseTrigger)
   else error("expected exactly one registry entry for \($name), got \($m | length)") end'`. Two
   cases, `none` versus anything else. When it
   reads `none`, report that no
   release is configured, dispatch and run-correlation (step 6) do not apply. Otherwise, dispatch
   explicitly, `gh workflow run publish-release.yml --ref main --repo owner/repo`, or `--ref
   develop` only when the maintainer explicitly asked for a prerelease dispatch instead.
6. Correlate the specific run this dispatch produced rather than assuming the newest one is it.
   `gh run list --repo owner/repo --workflow publish-release.yml --branch main --event
   workflow_dispatch --json databaseId,createdAt,headSha` (or `--branch develop` for a prerelease
   dispatch), matched by `headSha` against the dispatched ref's tip (`main`'s tip confirmed in
   step 4, or `develop`'s current tip for a prerelease) and by `createdAt` against the dispatch
   time. `gh run list` can momentarily omit a just-created run, so a single query reporting zero
   candidates is not yet "never started". Poll the list itself, within a bounded interval, until
   exactly one candidate matches. A concurrent run of a different event on the same branch must
   never be mistaken for this one, more than one candidate is as inconclusive as zero. A run whose
   `headSha` does not match the expected tip at all, rather than simply being absent, means the
   dispatched ref moved between step 4's confirmation and the dispatch itself, report that
   distinctly, the ref changed mid-dispatch, rather than folding it into an ordinary absent-run
   timeout. Report and stop rather than guessing once the interval elapses with zero or more than
   one candidate still matching. Only once exactly one candidate is confirmed, poll that one run
   id to completion in one further bounded background wait with an explicit, finite timeout,
   2700 seconds (45 minutes, matching `scripts/pr_review.py`'s own default) unless the maintainer
   states a different bound for this specific release: `timeout 2700 gh run watch <run-id> --repo
   owner/repo --exit-status` on a host with GNU `timeout`, or the equivalent bounded-wait
   mechanism enforcing the same bound on a host without it (macOS without coreutils, native
   Windows). Never pipe `gh run watch` into another command unless the shell running it sets
   `pipefail`, since without it a pipeline reports its last stage's exit status and
   `gh run watch ... | tail` reports whether `tail` succeeded rather than whether the run
   did. Read the watch's own exit status, or read the conclusion back with
   `gh run view <run-id> --repo owner/repo --json status,conclusion`.
   Report a timeout separately from a completed run's own conclusion, the tag or
   version it produced. A run that fails, times out, or never starts is reported, never silently
   retried.
7. In the hub, when the chosen scope includes a release, refresh this machine's Codex and opencode
   copy from the promoted `main` in a detached worktree of its own, never by switching an existing
   checkout to `main`, since the checkout Claude Code loads in place would move with it. Run `git fetch origin main`, then `git worktree add --detach
   <worktree> origin/main` at a new path in the fleet worktree layout, and from that worktree run
   `python3 scripts/skills_install.py --snapshot-only`, then `python3 scripts/skills_install.py
   --report`, and confirm its snapshot reads current. A fresh worktree holds nothing uncommitted
   or ignored under `.agents/skills/` or `.claude-plugin/`, the two paths the installer reads, so
   the copy holds exactly the promoted commit. `--snapshot-only` leaves the Claude Code
   registration untouched, and that channel needs no refresh here: it loads the registered
   directory in place, the one `--report` names under `live`, and serves whatever it holds at
   read time, so where that is the primary checkout on `develop`, Claude Code sessions on this
   machine load `develop`. Where `live.vcs` reads `archive`, that directory is the tree the hub's
   `host-setup/bootstrap.sh` or `bootstrap.ps1` keeps rather than a checkout, and it holds what
   that bootstrap fetched, the commit `live.commit` names where it is not null, until
   `bootstrap.sh --skills` or `bootstrap.ps1 -Skills` runs again, which this step does not do.
   From the same worktree, also run `python3 host-setup/agent-safety/claude/install.py --report`,
   and report any result other than CURRENT to the maintainer. The host-safety kit, its rendered
   `CLAUDE.md` included, is refreshed only by its own installer. That installer rewrites this
   machine's hooks and settings, so this step reports it rather than running it.
   Then remove the worktree with
   `git worktree remove <worktree>`, whatever either report said. Removing it leaves the skills
   snapshot and its stamp unchanged, and a result that does not read current is reported to the
   maintainer. The skills `--report` exits on the snapshot alone. This step runs whether step 5
   or 6 dispatched, skipped, or failed a release, since it is gated only on the chosen scope,
   never on the release outcome. This refreshes only the machine running
   this session, per skill-lifecycle, every other machine still refreshes on its own next run or
   `docs/host-setup.md` "Fleet Skills Install" cadence.
8. Run cleanup regardless of how steps 5 through 7 ended, no release configured, a dispatch
   failure, an ambiguous run match, a timeout, a failed run, or a hub Skills refresh all still
   reach this step, the merge in step 3 already landed by then. Two parts, both required, neither
   optional:
   - The promotion PR's own worktree: fetch and prune, remove the worktree, then bring the base
     clone to current `develop`, checking `develop` out first only where it sits on another
     branch, and fast-forwarding it with `git merge --ff-only origin/develop`. Where that checkout
     is needed, removing first, not after, matters: the base clone cannot check out `develop`
     while the promotion worktree still has it checked out, one branch checked out in two
     worktrees at once is refused outright. Never delete `develop`, it is the promotion PR's
     own head, and the repo's auto-delete-head-branches setting is kept off fleet-wide for exactly
     this reason, so nothing does this automatically.
   - A defensive sweep for anything drive-pr's own cleanup should already have removed but might
     not have, an interrupted loop, a fix landed by hand outside that skill, or a maintainer
     merge in the GitHub UI. `git worktree list` for any worktree still registered under this
     task's feature branches, `git branch -vv` for any local feature branch, `git ls-remote
     --heads origin` for any matching remote feature branch. For each, verify it finished by
     reading GitHub's own state with the exact fields this check needs, not a bare listing, and
     stop and report rather than guessing when selection is not exactly one match, on a non-1
     count exit non-zero rather than returning empty with success, an ambiguous or missing match
     must fail loud, not read as an empty value still safe to act on: `gh pr list --head
     "<branch>" --state merged --repo owner/repo --json
     number,baseRefName,mergedAt,headRefOid,headRefName,headRepository --jq 'if length == 1 then
     .[0] else error("expected exactly one merged PR for this head, got \(length)") end'`.
     `--head` is expected to match exactly (verified against `gh` 2.97.0 on this repo, a bare
     prefix of a real branch name returned nothing), but confirming `headRefName` equals `<branch>`
     costs one field and is cheap insurance against a future `gh` behavior change, not a workaround
     for a known partial-match case. Confirm `headRepository` is non-null and its `nameWithOwner` equals
     `owner/repo`, the owner alone is not enough, a same-owner PR against an identically named
     branch in a different repository must never pass this check either. Confirm `baseRefName`
     is `develop` (a different merged pull request can share the same head branch name against a
     different base, and that is never this sweep's target) and `mergedAt` is set. Compare tips
     only where a remote branch actually exists. `git ls-remote --heads --exit-code -- origin
     "refs/heads/<branch>"` is the exact-match form and must be, in that argument order. `--heads
     origin "<branch>"` alone still tail-matches, a bare `topic/x` pattern also returns an unrelated
     `other/topic/x` if one exists. `--` placed after `origin` instead of before it is not
     equivalent either, verified empirically: with a `refs/heads/other/--` ref present, `--heads
     origin -- "refs/heads/<branch>"` matched both that ref and the intended one, while `--heads --
     origin "refs/heads/<branch>"` matched only the one intended. Exit status is a tri-state, not a
     stdin-emptiness check: `--exit-code` makes exit `2` mean query succeeded, branch gone, most
     likely a prior cleanup attempt got interrupted after the remote delete but before the local
     one, so skip straight to the local-tip check below and never attempt the remote delete a
     second time. Exit `0` means it matched. Anything else is a failed query, a network or auth
     problem, and stops and reports rather than being read as absence, an unreachable remote and a
     genuinely gone branch both print nothing to stdout, only the exit code tells them apart.
     Where the remote branch does exist, its tip must match that exact pull request's `headRefOid`
     before its own delete proceeds, proving nothing landed on it since. Where a local branch
     still exists too, its tip (`git rev-parse --verify "refs/heads/<branch>"`) must independently
     match `headRefOid` before its own delete proceeds. Neither side needs the other to exist, a
     prior interrupted attempt may have deleted one side already and left only the other, so
     verify and delete whichever side is still there and skip whichever already is not, never
     block one side's cleanup on the other side's absence. No `--` on `rev-parse`, verified
     empirically: `git rev-parse -- "<branch>"` treats the argument after `--` as a path rather
     than a revision and never resolves a SHA at all. The fully-qualified form needs no `--`
     regardless, since `refs/heads/<branch>` never itself starts with `-`, and `--verify` fails
     loudly rather than guessing when it does not resolve. Every branch or
     worktree-path placeholder below is the real value, substituted as its own quoted argument
     (a shell variable expansion such as `"$branch"`, or an argv element), never handed to `eval`
     or `sh -c` for a second round of shell parsing, the only way an embedded `$()` or backtick
     would actually run. A valid ref can start with `-` or carry a shell metacharacter, which is
     why it stays quoted regardless. `--` marks the
     end of options wherever a command supports it.
     `git merge-base --is-ancestor <branch> develop` must never be used for either tip check, a
     squash merge (drive-pr's own merge method) never makes the feature tip a literal ancestor of
     `develop`, so the check reports every already-finished branch as unmerged. Only once GitHub
     confirms it, and only when a local worktree or branch is still there to remove, remove the
     worktree by its exact path (a dirty worktree stops cleanup rather than discarding uncommitted
     work), `git worktree remove "<worktree-path>"`, `git worktree list` names it, then delete the
     local branch. `git branch
     -d` has the identical squash blindness as `git merge-base --is-ancestor` and refuses too, so
     use `git branch -D -- "<exact-branch>"` here, safe only because the GitHub-state check just
     proved that exact branch finished, the narrow post-squash exception git-commit-conventions
     describes, never applied to an unverified branch. Then, only when the remote branch still
     exists, delete it the same way, `git push origin --delete -- "<branch>"`.
     Never `--force-with-lease` here, git-commit-conventions
     forbids it unconditionally, the GitHub-state check just completed is the verification gate,
     not a compare-and-swap at delete time. Never apply this sweep to `develop` or `main`
     themselves, only to feature branches a drive-pr loop created.

## Mechanics Live Elsewhere

- The Merge Gate itself: pr-review-conduct.
- Never delete develop, no-op republish, the operational repos' dispatch-only model:
  branching-and-release-model.
- What the dispatch actually builds and publishes: workflow-ci-contract.
- Skills install and report semantics: skill-lifecycle.
- Cleanup mechanics: repo-worktree.

## Stop and Report, Never Guess

- A merge conflict, a newly failing check, or a gate item that regressed since drive-pr finished
  are each a stop, report the exact state, never force or retry blindly.
- A merge refused by `--match-head-commit` means the head moved past the SHA it was given.
  Attended, stop and report the commits added, named as step 2 names them, and never retry with
  the new SHA on the old go-ahead. Under an `unattended-handoff` grant, re-run step 2 on the new head instead.
- `gh pr merge` or `gh workflow run` failing is reported with its actual output, never
  suppressed, never assumed harmless on the agent's side alone.
