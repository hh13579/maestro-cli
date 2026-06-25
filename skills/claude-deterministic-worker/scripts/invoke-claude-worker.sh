#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <run-dir>" >&2
  exit 2
fi

run_dir="$1"
task_file="$run_dir/task.md"
settings_file="$run_dir/claude-settings.json"
schema_file="$run_dir/result.schema.json"
result_file="$run_dir/result.json"

for file in "$task_file" "$settings_file" "$schema_file"; do
  if [[ ! -f "$file" ]]; then
    echo "missing required file: $file" >&2
    exit 1
  fi
done

if ! command -v claude >/dev/null 2>&1; then
  echo "claude command not found. Install and authenticate Claude Code CLI before using this worker." >&2
  exit 127
fi

# Validate JSON files before invoking Claude.
python3 -m json.tool "$settings_file" >/dev/null
python3 -m json.tool "$schema_file" >/dev/null

claude --bare \
  --settings "$settings_file" \
  --no-session-persistence \
  --output-format json \
  --json-schema "$(cat "$schema_file")" \
  --max-turns "${CLAUDE_WORKER_MAX_TURNS:-6}" \
  -p "$(cat "$task_file")" \
  > "$result_file"

echo "Claude worker result written to $result_file"
