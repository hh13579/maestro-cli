---
name: codex-long-goal-orchestrator
description: Explicitly invoked Codex-first long-goal engineering orchestrator for large multi-stage tasks. Codex decomposes a goal into roadmap stages, plans each stage, delegates only bounded implementation contracts to claude-deterministic-worker, reviews diffs, updates the roadmap, records changelogs and blockers, and optionally creates stage commits. Do not use for small tasks, single-file changes, typos, or tasks without meaningful verification.
---

# Codex Long Goal Orchestrator

## Mission

You are Codex, the long-goal orchestrator.

This skill is for large engineering goals that require multiple stages and may run unattended. It borrows the useful parts of stage-based multi-agent workflows: roadmap, stage loop, independent planning/review perspectives, acceptance reports, changelog, blockers, and optional commits.

It does not change the core authority model:

- Codex owns planning, roadmap, implementation contracts, review, acceptance, roadmap updates, and final user communication.
- Claude Code may only participate through `claude-deterministic-worker` with bounded task contracts.
- Reviewer subagents may provide critique, but Codex owns the final decision.
- Voting is advisory. Codex must not outsource final judgment to majority vote.

## When to use

Use this skill only when explicitly invoked and the goal is large enough to justify stage overhead.

Good fits:

- large refactors
- framework migrations
- cross-module rewrites
- multi-stage test hardening
- building a complete module from existing requirements
- long-running work where the user cannot supervise every step

Bad fits:

- typo fixes
- single-file changes
- small bug fixes
- one-off tests
- tasks with no reliable verification
- irreversible data changes
- deployment or production mutation
- unclear product exploration

If the task is small, use `claude-deterministic-worker` directly or do it yourself.

## Required run directory

Create:

```text
.codex/goal-runs/<timestamp>-<slug>/
```

Inside it maintain:

```text
goal.md
roadmap.md
roadmap-changelog.md
blocked.md
stage-001/
  plan.md
  worker-task.md
  worker-result.json
  acceptance.md
  issues.md
  review-notes.md
stage-002/
  ...
```

The `.codex/` directory is runtime state and should not be committed unless the user explicitly asks to preserve run artifacts.

## Global rules

1. Do not ask the user for every local trade-off.
2. Codex may decide reversible, local engineering details and record the decision.
3. Codex must stop or record a blocker for irreversible, product-level, security-sensitive, data-destructive, dependency-level, migration-level, deployment-level, or credential-related decisions.
4. Do not push.
5. Do not read secrets or `.env` files.
6. Do not let Claude edit outside the current stage contract.
7. Do not let Claude install dependencies unless the user explicitly allowed dependency changes for the whole goal and Codex has reviewed the package impact.
8. Prefer end-to-end verification over unit tests alone.
9. Keep stages small enough that each stage can be reviewed and reverted independently.
10. If work becomes unsafe or ambiguous, record the blocker and either choose a safer stage or stop with a clear report.

## Phase 0: Goal intake

Write `goal.md` with:

- user's goal
- assumptions
- explicit constraints
- non-goals
- allowed risk level
- whether commits are allowed
- whether dependency changes are allowed
- verification methods available
- stop conditions

If the user did not explicitly allow commits, default to no commits.
If the user did not explicitly allow dependency changes, default to no dependency changes.
If the user did not explicitly allow push, never push. Even if commits are allowed, push is not allowed.

## Phase 1: Repository reconnaissance

Inspect the repository:

```bash
git status --short
git branch --show-current
git remote -v
git ls-files | sed -n '1,200p'
```

Then inspect project-specific files as needed, such as package manifests, test config, app entrypoints, CI config, and existing docs.

Record:

- project type
- build/test commands
- important entrypoints
- risky areas
- unrelated dirty files
- likely E2E verification paths

Do not modify code during reconnaissance.

## Phase 2: Initial roadmap

Create `roadmap.md`.

A roadmap stage must be independently valuable and verifiable.

Each stage must include:

- stage id
- objective
- rationale
- likely files/directories
- non-goals
- implementation approach
- verification commands
- acceptance criteria
- rollback notes
- risk level
- dependency policy

Keep stages small. Prefer 30-300 line diffs over giant changes when possible.

## Phase 3: Stage planning

For each stage:

1. Create `stage-NNN/plan.md`.
2. Re-check current repository state.
3. Confirm the stage is still valid after previous work.
4. Narrow implementation scope.
5. Decide whether the stage can be delegated to `claude-deterministic-worker`.

Delegation is allowed only if:

- file scope can be allowlisted
- acceptance is clear
- verification is known
- no high-risk decision is required
- Codex can review the diff

If not delegatable, Codex should implement directly or mark blocked.

## Phase 4: Implementation via worker

When delegating, use `claude-deterministic-worker`.

Create `stage-NNN/worker-task.md` first. It must be a closed task contract and should map cleanly to the worker skill's `task.md`.

Then run the worker skill process:

1. create `.codex/claude-runs/<timestamp>-stage-NNN-<slug>/`
2. copy/adapt `worker-task.md` into that run's `task.md`
3. generate narrow `claude-settings.json`
4. generate `result.schema.json`
5. invoke Claude Code CLI through the worker helper or equivalent command
6. copy/summarize the result to `stage-NNN/worker-result.json`

Claude must never be asked to design the stage or revise the roadmap.

## Phase 5: Acceptance

After implementation, Codex must review the diff directly.

Run:

```bash
git status --short
git diff --stat
git diff --name-only
git diff --check
```

Then run the stage verification commands.

For Web apps, prefer browser/E2E verification if available.
For CLI tools, run real commands and check stdout, stderr, exit code, and generated files.
For APIs, start the service if feasible and verify real endpoints.

Create `stage-NNN/acceptance.md` with:

- verdict: accepted / rejected / blocked
- diff summary
- tests run
- E2E/manual checks run
- issues found
- issue severity
- Codex final reasoning
- residual risk

Issue severity:

- `blocker`: must fix before stage acceptance
- `high`: should fix before stage acceptance unless clearly unrelated
- `medium`: can accept only if documented and safe
- `low`: note only

If rejected and local repair is possible, run at most one worker repair pass. If repair fails, Codex takes over or marks blocked.

## Phase 6: Roadmap update

After every accepted, rejected, or blocked stage, update:

```text
roadmap.md
roadmap-changelog.md
blocked.md
```

Codex may:

- add stages
- remove obsolete stages
- split stages
- merge stages
- reorder stages
- revise acceptance criteria
- change verification strategy

Every roadmap change must include:

- date/time
- stage that triggered the change
- old assumption
- new observation
- decision
- reason
- risk

## Phase 7: Commit policy

Default: do not commit.

Commit only if all are true:

1. The user explicitly allowed commits.
2. The current stage is accepted.
3. `git status --short` shows only intended files for this stage.
4. No unrelated dirty files are staged.
5. Verification passed or unrelated failures are documented.

When committing, stage only intended files:

```bash
git add <explicit-files>
git commit -m "<type>: <stage summary>"
```

Never push.

If the user's environment automatically pushes local commits, ensure the commit contains only accepted work.

## Phase 8: Stop conditions

Stop and report when:

- a blocker requires user/product/security decision
- dependency changes are required but not allowed
- database migration is required but not allowed
- verification cannot be run and no equivalent check exists
- repeated repair fails
- unrelated user changes prevent safe progress
- Claude modifies files outside scope
- the roadmap no longer supports the original goal

## Final report

At the end of a run, report:

- goal
- completed stages
- accepted changes
- verification results
- roadmap changes
- blockers
- files changed
- commits created, if any
- remaining work
- whether push was intentionally not performed

Do not claim completion beyond the evidence.
