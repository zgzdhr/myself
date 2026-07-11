#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

run_step() {
  local label="$1"
  local timeout_seconds="$2"
  shift
  shift

  if run_with_timeout "$timeout_seconds" "$@"; then
    echo "PASS: $label"
  else
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  fi
}

run_with_timeout() {
  local timeout_seconds="$1"
  shift

  "$@" &
  local command_pid=$!
  (
    sleep "$timeout_seconds"
    if kill -0 "$command_pid" 2>/dev/null; then
      echo "TIMEOUT: command exceeded ${timeout_seconds}s" >&2
      kill -TERM "$command_pid" 2>/dev/null || true
    fi
  ) &
  local watchdog_pid=$!

  local status=0
  wait "$command_pid" || status=$?
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  return "$status"
}

run_step "mobile analyze" 300 bash -lc "cd '$ROOT_DIR/apps/mobile' && flutter analyze"
run_step "mobile tests" 600 bash -lc "cd '$ROOT_DIR/apps/mobile' && flutter test"
run_step "API typecheck" 120 bash -lc "cd '$ROOT_DIR/apps/api' && npm run typecheck"
run_step "API tests" 300 bash -lc "cd '$ROOT_DIR/apps/api' && npm test"

if (( failures > 0 )); then
  echo "Verification completed with $failures failing lane(s)." >&2
  exit 1
fi

echo "Verification completed: all lanes passed."
