# Codex Claude Orchestrator Skills

Codex-first orchestration skills for long-running engineering goals, with Claude Code constrained to deterministic worker tasks.

## 这是什么

本仓库提供两个 Agent Skills：

1. `claude-deterministic-worker`
2. `codex-long-goal-orchestrator`

核心原则：Codex 负责规划、任务合同、Review、验收与最终裁决；Claude Code CLI 只负责边界明确的实现任务。

## Design Summary

Codex owns orchestration, task contracts, review, verification, and acceptance. Claude Code is used only as a constrained implementation worker with explicit file and command boundaries.

## 设计背景

过去一年，spec-driven / plan-first / SDD 工作流已经成为 AI 辅助开发中的常见模式。但大型工程任务仍有三个问题：

- 前期 spec 难以穷尽所有细节。
- 中途发现现实约束后，roadmap 需要持续修订。
- 使用者不希望每个 trade-off 都人工裁定。

本项目采用两层设计：

- 长程目标由 `codex-long-goal-orchestrator` 阶段化推进。
- 每个阶段中确定性实现任务由 `claude-deterministic-worker` 交给 Claude Code CLI 执行。

## Skill 1: claude-deterministic-worker

适合：

- 修复已知 lint/type/test failure
- 给已有行为补测试
- 小范围实现
- 文件 allowlist 明确的机械重构
- 根据 Codex 提供的错误日志做局部修复

不适合：

- 架构设计
- API 合同设计
- 数据迁移
- 安全、权限、支付、隐私、密钥相关修改
- 依赖升级
- 部署、CI 凭据、release 操作
- 宽泛重构

## Skill 2: codex-long-goal-orchestrator

适合：

- 长周期工程目标
- 多阶段迁移
- 大型重构
- 从零搭建模块
- 用户无法持续盯着屏幕的无人值守推进

不适合：

- typo
- 单文件小改
- 添加一个按钮
- 无法测试的产品探索
- 不可逆高风险操作

## 安装

推荐让 Codex 直接安装单个 Skill：

```text
Install this skill: https://github.com/hh13579/maestro-cli/tree/main/skills/claude-deterministic-worker
```

```text
Install this skill: https://github.com/hh13579/maestro-cli/tree/main/skills/codex-long-goal-orchestrator
```

也可以使用 skills CLI：

```bash
npx skills add hh13579/maestro-cli --skill claude-deterministic-worker --agent codex
npx skills add hh13579/maestro-cli --skill codex-long-goal-orchestrator --agent codex
```

一次安装两个：

```bash
npx skills add hh13579/maestro-cli \
  --skill claude-deterministic-worker \
  --skill codex-long-goal-orchestrator \
  --agent codex
```

如果安装后 Agent 没有立即识别，重启 Codex。

## 使用方式

本项目的两个 Skill 都必须显式调用。`agents/openai.yaml` 中设置了 `allow_implicit_invocation: false`，避免 Agent 在普通任务中自动启用这些工作流。

### 小型确定性任务

```text
$claude-deterministic-worker
Codex 先制定方案，然后把实现任务交给 Claude Code CLI。只允许修改 src/date/parseDate.ts 和 tests/date/parseDate.test.ts。目标是修复 2023-02-29 被错误接受的问题，并补测试。
```

### 长周期工程目标

```text
$codex-long-goal-orchestrator
目标：把这个 Express 项目迁移到 Fastify，保持现有 API 行为不变。所有现有集成测试和 E2E 测试必须继续通过。每个阶段完成后更新 roadmap，但不要 push。
```

## Claude Code CLI 前置条件

使用 `claude-deterministic-worker` 时，本机需要可执行 `claude` 命令，并且 Claude Code 已完成认证或配置了可用的 API key/helper。

worker 默认使用：

- `claude --bare`
- `claude -p`
- `--output-format json`
- `--json-schema`
- `--settings`
- `--max-turns`
- `--no-session-persistence`

## 安全模型

- Codex 永远是最终裁决者。
- Claude 的自然语言报告不作为验收依据。
- Claude 只能修改任务合同允许的文件。
- Claude 只能运行任务合同允许的命令。
- Claude 不允许 commit、push、安装依赖、读取密钥、访问 `.env`、做部署操作。
- 对安全、权限、支付、隐私、数据迁移等高风险任务，Codex 必须停止或记录 blocker，不得让 Claude 猜。

## 推荐工作流

1. 用户显式调用 orchestrator。
2. Codex 创建 `.codex/goal-runs/<timestamp>-<slug>/`。
3. Codex 生成初始 roadmap。
4. 每个阶段独立 plan / implement / accept / update roadmap。
5. 实现阶段通过 `claude-deterministic-worker` 创建 worker contract。
6. Claude Code CLI 只执行 contract。
7. Codex 审 diff、跑验证、决定是否接受。
8. 每阶段结束后更新 `roadmap.md` 和 `roadmap-changelog.md`。
9. 只有用户明确允许时才 commit。
10. 永远不要自动 push。

## 仓库结构

```text
.
├── README.md
├── LICENSE
├── .gitignore
├── package.json
├── scripts/
│   └── validate-skill-layout.sh
├── examples/
│   ├── bounded-worker-task.md
│   └── long-goal-express-to-fastify.md
└── skills/
    ├── claude-deterministic-worker/
    │   ├── SKILL.md
    │   ├── agents/
    │   │   └── openai.yaml
    │   ├── references/
    │   │   ├── claude-worker-contract-template.md
    │   │   ├── claude-worker-result.schema.json
    │   │   └── claude-settings-template.json
    │   └── scripts/
    │       └── invoke-claude-worker.sh
    └── codex-long-goal-orchestrator/
        ├── SKILL.md
        ├── agents/
        │   └── openai.yaml
        └── references/
            ├── roadmap-template.md
            ├── stage-plan-template.md
            ├── acceptance-report-template.md
            ├── roadmap-changelog-template.md
            └── blocked-template.md
```

## 验证

```bash
bash scripts/validate-skill-layout.sh
npm test
```

`npm test` 只调用本仓库的 shell 验证脚本，不安装任何依赖。

## License

MIT
