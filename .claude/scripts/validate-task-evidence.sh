#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <task-execution-report.md>"
  exit 2
fi

report_file="$1"

if [[ ! -f "$report_file" ]]; then
  echo "ERROR: report file not found: $report_file"
  exit 2
fi

missing=0

require_pattern() {
  local pattern="$1"
  local label="$2"

  if ! grep -Eiq "$pattern" "$report_file"; then
    echo "MISSING: $label"
    missing=1
  fi
}

# Required sections
require_pattern "executed commands" "Executed commands section"
require_pattern "changed files" "Changed files section"
require_pattern "validation results" "Validation results section"
require_pattern "assumptions" "Assumptions section"
require_pattern "residual risks" "Residual risks section"

# Require a terminal canonical state
if ! grep -Eiq "state[[:space:]]*:[[:space:]]*(blocked|failed|done)" "$report_file"; then
  echo "MISSING: Terminal execution state (blocked|failed|done)"
  missing=1
fi

# Test and lint evidence
require_pattern "test(s)?[[:space:]]*:[[:space:]]*(pass|fail|blocked)" "Test evidence with result"
require_pattern "lint[[:space:]]*:[[:space:]]*(pass|fail|blocked)" "Lint evidence with result"

# Reviewer verdict
if ! grep -Eiq "reviewer verdict[[:space:]]*:[[:space:]]*(APPROVED|APPROVED_WITH_REMARKS|REJECTED|BLOCKED)" "$report_file"; then
  echo "MISSING: Reviewer verdict with canonical enum value"
  missing=1
fi

if [[ $missing -ne 0 ]]; then
  echo ""
  echo "Evidence bundle validation failed: $report_file"
  exit 1
fi

echo "Evidence bundle validation passed: $report_file"
