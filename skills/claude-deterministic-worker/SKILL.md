---
name: claude-deterministic-worker
description: Explicitly invoked Codex workflow for delegating bounded deterministic implementation, test-writing, mechanical refactor, or local repair tasks to Claude Code CLI. Codex writes the task contract, invokes Claude in bare/headless mode, reviews the diff, runs verification, and owns final acceptance. Do not use for architecture, ambiguous requirements, security-sensitive work, migrations, dependency changes, deployment, or broad refactors.
---

# Claude Deterministic Worker

## Mission

You are Codex, the orchestrator.

Claude Code CLI is only a bounded implementation worker. Codex owns all planning, decomposition, task contracts, review, verification, acceptance, and final communication.

Claude owns only:

- implementing the exact task contract
- editing only explicitly allowed files
- running only explicitly allowed local commands
- returning structured evidence of what it changed
- stopping when scope is unclear or unsafe

Never treat Claude's natural-language report as proof. The only proof is repository state, diff, command output, tests, lint, typecheck, runtime checks, and Codex's own review.

## Delegation boundary

Use this skill only when all are true:

1. The task can be written as a closed contract.
2. Editable files or directories can be allowlisted.
3. Non-goals can be stated explicitly.
4. Verification commands are known or can be inferred locally.
5. The expected diff is small enough for Codex to review.
6. No architecture, product, security, dependency, deployment, migration, or irreversible decision is required.

Good tasks:

- fix a known lint/type/test failure
- add tests for already specified behavior
- implement a small function from an existing spec
- update mechanical API usages in an explicit file list
- perform a scoped refactor with no intended behavior change
- repair a local failure using supplied logs

Never delegate:

- requirements discovery
- architecture or API design
- database schema or data migrations
- auth, permissions, crypto, payment, privacy, or secrets work
- dependency add/upgrade/remove
- deployment, release, CI credential, or infra mutation
- broad refactors without exact scope
- destructive commands or data deletion
- tasks requiring external network access
- tasks Codex cannot personally review

## Required run directory

For each delegation, create:

```text
.codex/claude-runs/<timestamp>-<slug>/
```

Inside it, write:

```text
task.md
claude-settings.json
result.schema.json
result.json
review.md
```

Use the templates in `references/` when helpful.

## Step 1: Preflight

Before calling Claude:

1. Inspect relevant code yourself.
2. Run `git status --short`.
3. Identify unrelated dirty files.
4. Protect unrelated dirty files from worker changes.
5. Determine exact read scope and edit scope.
6. Determine allowed verification commands.
7. Decide repair budget. Default: one implementation pass plus one repair pass.
8. If the repo has unrelated dirty changes, do not stage, commit, overwrite, or revert them.

If safe delegation is impossible, do the work yourself or report a blocker.

## Step 2: Write the task contract

Write `.codex/claude-runs/<timestamp>-<slug>/task.md`.

The contract must include:

- Role
- Objective
- Context
- File scope
- Non-goals
- Implementation constraints
- Verification commands
- Success criteria
- Output format
- Stop conditions

Claude must be instructed to return `blocked` if it needs to edit files outside scope, install dependencies, run unapproved commands, read secrets, make design decisions, or access the network.

## Step 3: Generate Claude settings

Write `.codex/claude-runs/<timestamp>-<slug>/claude-settings.json`.

Rules:

- Keep `Edit(...)` as narrow as possible.
- Deny `.env`, secrets, SSH, cloud credentials, package manager install commands, git commit, git push, and destructive commands.
- Enable sandboxing when available.
- Set `sandbox.failIfUnavailable` to `true` for high-risk runs.
- Do not allow unsandboxed commands unless Codex has a specific reason and documents it.

## Step 4: Generate result schema

Write `.codex/claude-runs/<timestamp>-<slug>/result.schema.json` from `references/claude-worker-result.schema.json`.

## Step 5: Invoke Claude

Prefer the helper script:

```bash
skills/claude-deterministic-worker/scripts/invoke-claude-worker.sh \
  .codex/claude-runs/<timestamp>-<slug>
```

The helper should run Claude Code CLI in bare non-interactive mode with structured output.

If calling directly, use this shape:

```bash
RUN_DIR=".codex/claude-runs/<timestamp>-<slug>"

claude --bare \
  --settings "$RUN_DIR/claude-settings.json" \
  --no-session-persistence \
  --output-format json \
  --json-schema "$(cat "$RUN_DIR/result.schema.json")" \
  --max-turns 6 \
  -p "$(cat "$RUN_DIR/task.md")" \
  > "$RUN_DIR/result.json"
```

Do not pass secrets in the prompt.
Do not pass broad repository context.
Do not use `--dangerously-skip-permissions`.

## Step 6: Review the result

After Claude returns, Codex must inspect the repository directly:

```bash
git status --short
git diff --stat
git diff --name-only
git diff --check
```

Then review:

1. Every changed file is within the allowlist.
2. No unrelated dirty file changed.
3. No dependency or lockfile changed unless explicitly allowed.
4. No CI, credential, generated, or config file changed unless explicitly allowed.
5. The implementation matches the contract.
6. The change is minimal.
7. Tests cover the requested behavior when tests were requested.
8. Verification commands pass, or failures are clearly unrelated/environmental.
9. There is no hidden architecture drift.
10. There is no security-sensitive behavior change.

Write `.codex/claude-runs/<timestamp>-<slug>/review.md` with Codex's verdict.

## Step 7: Repair loop

Use at most one repair pass by default.

A repair pass is allowed only when:

- the diff is within scope
- the failure is local and deterministic
- Codex can provide exact failing command output
- no new design decision is needed

For repair, create a new `repair-1.md` task contract in the same run directory. Include:

- original objective
- current diff summary
- exact failing command
- exact failure excerpt
- instruction to make the smallest possible fix

If repair fails, Codex takes over or reports a blocker. Do not loop indefinitely.

## Step 8: Acceptance

Accept the worker result only when:

- diff is scoped and reviewed
- verification passes or any failure is unrelated and documented
- success criteria are met
- Codex can explain the result from repository evidence

If accepted, leave changes in the working tree for the caller or orchestrator to commit. This skill must not push.

## Final response pattern

When reporting to the user or caller, Codex should state:

- what was delegated
- what Claude changed
- what Codex reviewed
- what verification ran
- whether the result was accepted
- any residual risk or blocker

Never say the work is correct merely because Claude said it is correct.
