#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "README.md"
  "LICENSE"
  "package.json"
  "skills/claude-deterministic-worker/SKILL.md"
  "skills/claude-deterministic-worker/agents/openai.yaml"
  "skills/claude-deterministic-worker/references/claude-worker-contract-template.md"
  "skills/claude-deterministic-worker/references/claude-worker-result.schema.json"
  "skills/claude-deterministic-worker/references/claude-settings-template.json"
  "skills/claude-deterministic-worker/scripts/invoke-claude-worker.sh"
  "skills/codex-long-goal-orchestrator/SKILL.md"
  "skills/codex-long-goal-orchestrator/agents/openai.yaml"
  "skills/codex-long-goal-orchestrator/references/roadmap-template.md"
  "skills/codex-long-goal-orchestrator/references/stage-plan-template.md"
  "skills/codex-long-goal-orchestrator/references/acceptance-report-template.md"
  "skills/codex-long-goal-orchestrator/references/roadmap-changelog-template.md"
  "skills/codex-long-goal-orchestrator/references/blocked-template.md"
  "examples/bounded-worker-task.md"
  "examples/long-goal-express-to-fastify.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "missing required file: $file" >&2
    exit 1
  fi
done

for skill in skills/claude-deterministic-worker skills/codex-long-goal-orchestrator; do
  if ! grep -q '^name:' "$skill/SKILL.md"; then
    echo "missing name frontmatter in $skill/SKILL.md" >&2
    exit 1
  fi
  if ! grep -q '^description:' "$skill/SKILL.md"; then
    echo "missing description frontmatter in $skill/SKILL.md" >&2
    exit 1
  fi
  if ! grep -q 'allow_implicit_invocation: false' "$skill/agents/openai.yaml"; then
    echo "missing allow_implicit_invocation false in $skill/agents/openai.yaml" >&2
    exit 1
  fi
done

python3 -m json.tool skills/claude-deterministic-worker/references/claude-worker-result.schema.json >/dev/null
python3 -m json.tool skills/claude-deterministic-worker/references/claude-settings-template.json >/dev/null

if [[ ! -x skills/claude-deterministic-worker/scripts/invoke-claude-worker.sh ]]; then
  echo "invoke-claude-worker.sh must be executable" >&2
  exit 1
fi

echo "skill layout validation passed"
