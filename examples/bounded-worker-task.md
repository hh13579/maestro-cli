# Example: Bounded Worker Task

Invocation:

```text
$claude-deterministic-worker
Codex 先制定方案，然后把实现任务交给 Claude Code CLI。目标是修复 src/date/parseDate.ts 的 leap day bug：2023-02-29 必须被拒绝，2024-02-29 必须被接受。只允许修改 src/date/parseDate.ts 和 tests/date/parseDate.test.ts。不要改 public API，不要改 timezone 行为，不要添加依赖。
```

Expected Codex behavior:

1. Inspect `src/date/parseDate.ts` and existing tests.
2. Create `.codex/claude-runs/.../task.md`.
3. Allow edits only to the two files.
4. Invoke Claude Code CLI in bare/headless mode.
5. Review diff.
6. Run targeted tests and typecheck.
7. Accept only if diff is scoped and verification passes.
