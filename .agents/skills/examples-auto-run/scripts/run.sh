#!/usr/bin/env bash
# examples-auto-run/scripts/run.sh
# Automatically discovers and runs all examples in the repository,
# capturing output and reporting pass/fail status.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
LOG_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/logs"
TIMEOUT_SECONDS="${EXAMPLES_TIMEOUT:-60}"
PYTHON_CMD="${PYTHON_CMD:-python}"

PASSED=0
FAILED=0
SKIPPED=0
FAILED_EXAMPLES=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[examples-auto-run] $*"; }
warn() { echo "[examples-auto-run] WARNING: $*" >&2; }
err()  { echo "[examples-auto-run] ERROR: $*" >&2; }

require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    err "Required command not found: $1"
    exit 1
  fi
}

setup_log_dir() {
  mkdir -p "${LOG_DIR}"
  log "Logs will be written to: ${LOG_DIR}"
}

# Return 0 if the example file should be skipped.
should_skip() {
  local file="$1"
  # Skip files that contain a special marker comment.
  grep -q '# skip-auto-run' "${file}" 2>/dev/null
}

# Run a single example file and return its exit code.
run_example() {
  local file="$1"
  local name
  name="$(basename "${file}" .py)"
  local log_file="${LOG_DIR}/${name}.log"

  log "Running: ${file}"
  if timeout "${TIMEOUT_SECONDS}" "${PYTHON_CMD}" "${file}" \
       > "${log_file}" 2>&1; then
    log "  PASSED: ${name}"
    return 0
  else
    local exit_code=$?
    if [[ ${exit_code} -eq 124 ]]; then
      warn "  TIMED OUT after ${TIMEOUT_SECONDS}s: ${name}"
    else
      warn "  FAILED (exit ${exit_code}): ${name}"
    fi
    return ${exit_code}
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  require_cmd "${PYTHON_CMD}"
  require_cmd timeout

  if [[ ! -d "${EXAMPLES_DIR}" ]]; then
    err "Examples directory not found: ${EXAMPLES_DIR}"
    exit 1
  fi

  setup_log_dir

  log "Discovering examples in: ${EXAMPLES_DIR}"

  # Collect all Python example files (non-recursive top-level + one level deep).
  mapfile -t EXAMPLE_FILES < <(
    find "${EXAMPLES_DIR}" -maxdepth 2 -name '*.py' | sort
  )

  if [[ ${#EXAMPLE_FILES[@]} -eq 0 ]]; then
    warn "No example files found."
    exit 0
  fi

  log "Found ${#EXAMPLE_FILES[@]} example file(s)."
  echo ""

  for file in "${EXAMPLE_FILES[@]}"; do
    if should_skip "${file}"; then
      log "  SKIPPED (marker found): ${file}"
      (( SKIPPED++ )) || true
      continue
    fi

    if run_example "${file}"; then
      (( PASSED++ )) || true
    else
      (( FAILED++ )) || true
      FAILED_EXAMPLES+=("${file}")
    fi
  done

  # ---------------------------------------------------------------------------
  # Summary
  # ---------------------------------------------------------------------------
  echo ""
  log "========================================"
  log "Results: ${PASSED} passed, ${FAILED} failed, ${SKIPPED} skipped"
  log "========================================"

  if [[ ${FAILED} -gt 0 ]]; then
    err "The following examples failed:"
    for f in "${FAILED_EXAMPLES[@]}"; do
      err "  - ${f}"
    done
    exit 1
  fi

  log "All examples passed."
}

main "$@"
