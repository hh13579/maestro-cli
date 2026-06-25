# Example: Long Goal Express to Fastify

Invocation:

```text
$codex-long-goal-orchestrator
目标：把这个 Express 项目迁移到 Fastify，保持现有 API 行为不变。所有现有集成测试和 E2E 测试必须继续通过。尽量分阶段推进，每个阶段都要独立验收。允许本地 commit，但不要 push。不要引入新依赖，除非迁移到 Fastify 的依赖已经由用户明确批准。
```

Expected stage breakdown:

1. Reconnaissance: map Express entrypoints, middleware, routes, tests.
2. Stage 001: introduce Fastify server skeleton behind existing interface.
3. Stage 002: migrate health/static/basic routes.
4. Stage 003: migrate API routes by group.
5. Stage 004: migrate middleware/error handling.
6. Stage 005: remove Express-only code after parity verification.
7. Stage 006: final E2E and cleanup.

Each implementation stage should delegate only bounded file scopes to `claude-deterministic-worker`.
