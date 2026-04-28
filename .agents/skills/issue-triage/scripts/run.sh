#!/usr/bin/env bash
# Issue Triage Skill - Automated script to triage GitHub issues
# Analyzes new issues, applies labels, assigns priority, and routes to appropriate team members

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
REPO="${REPO:-openai/openai-agents-python}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
ISSUE_NUMBER="${ISSUE_NUMBER:-}"
DRY_RUN="${DRY_RUN:-false}"

# Label definitions
LABEL_BUG="bug"
LABEL_FEATURE="enhancement"
LABEL_QUESTION="question"
LABEL_DOCS="documentation"
LABEL_DUPLICATE="duplicate"
LABEL_NEEDS_REPRO="needs-reproduction"
LABEL_PRIORITY_HIGH="priority: high"
LABEL_PRIORITY_LOW="priority: low"
LABEL_GOOD_FIRST_ISSUE="good first issue"

# ─── Helpers ──────────────────────────────────────────────────────────────────
log() { echo "[issue-triage] $*" >&2; }
error() { echo "[issue-triage] ERROR: $*" >&2; exit 1; }

require_env() {
  [[ -z "${!1:-}" ]] && error "Required environment variable '$1' is not set."
}

gh_api() {
  local endpoint="$1"; shift
  curl -sSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com${endpoint}" "$@"
}

apply_label() {
  local issue="$1" label="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[dry-run] Would apply label '${label}' to issue #${issue}"
    return
  fi
  log "Applying label '${label}' to issue #${issue}"
  gh_api "/repos/${REPO}/issues/${issue}/labels" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"labels\": [\"${label}\"]}" > /dev/null
}

post_comment() {
  local issue="$1" body="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[dry-run] Would post comment to issue #${issue}"
    return
  fi
  log "Posting triage comment to issue #${issue}"
  gh_api "/repos/${REPO}/issues/${issue}/comments" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"body\": $(echo "$body" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}" > /dev/null
}

# ─── Fetch Issue Data ─────────────────────────────────────────────────────────
fetch_issue() {
  local issue_number="$1"
  gh_api "/repos/${REPO}/issues/${issue_number}"
}

# ─── Classify Issue ───────────────────────────────────────────────────────────
classify_issue() {
  local title="$1" body="$2"
  local combined
  combined=$(echo "${title} ${body}" | tr '[:upper:]' '[:lower:]')

  # Bug indicators
  if echo "$combined" | grep -qE '(error|exception|traceback|crash|broken|fails|failure|bug|regression|unexpected behavior)'; then
    echo "bug"
    return
  fi

  # Feature request indicators
  if echo "$combined" | grep -qE '(feature request|would be nice|suggestion|add support|please add|enhancement|improve|wish)'; then
    echo "enhancement"
    return
  fi

  # Documentation indicators
  if echo "$combined" | grep -qE '(documentation|docs|readme|typo|misleading|unclear|example missing)'; then
    echo "documentation"
    return
  fi

  # Question indicators
  if echo "$combined" | grep -qE '(how to|how do|question|confused|help|what is|can i|is it possible)'; then
    echo "question"
    return
  fi

  echo "unknown"
}

assess_priority() {
  local title="$1" body="$2"
  local combined
  combined=$(echo "${title} ${body}" | tr '[:upper:]' '[:lower:]')

  if echo "$combined" | grep -qE '(critical|urgent|blocker|security|data loss|production|severe)'; then
    echo "high"
    return
  fi

  echo "low"
}

needs_reproduction() {
  local body="$1"
  local lower
  lower=$(echo "$body" | tr '[:upper:]' '[:lower:]')

  # Check if reproduction steps are missing
  if ! echo "$lower" | grep -qE '(steps to reproduce|reproduction|repro|minimal example|code snippet|```)'  ; then
    echo "true"
    return
  fi
  echo "false"
}

# ─── Main Triage Logic ────────────────────────────────────────────────────────
triage_issue() {
  local issue_number="$1"

  log "Fetching issue #${issue_number} from ${REPO}..."
  local issue_data
  issue_data=$(fetch_issue "$issue_number")

  local title body state
  title=$(echo "$issue_data" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("title",""))')
  body=$(echo "$issue_data" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("body") or "")')
  state=$(echo "$issue_data" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("state",""))')

  if [[ "$state" != "open" ]]; then
    log "Issue #${issue_number} is not open (state: ${state}). Skipping."
    return
  fi

  log "Classifying issue: '${title}'"
  local category priority
  category=$(classify_issue "$title" "$body")
  priority=$(assess_priority "$title" "$body")

  log "  → Category : ${category}"
  log "  → Priority : ${priority}"

  # Apply category label
  case "$category" in
    bug)           apply_label "$issue_number" "$LABEL_BUG" ;;
    enhancement)   apply_label "$issue_number" "$LABEL_FEATURE" ;;
    documentation) apply_label "$issue_number" "$LABEL_DOCS" ;;
    question)      apply_label "$issue_number" "$LABEL_QUESTION" ;;
    *)             log "Could not determine category — skipping category label" ;;
  esac

  # Apply priority label
  if [[ "$priority" == "high" ]]; then
    apply_label "$issue_number" "$LABEL_PRIORITY_HIGH"
  else
    apply_label "$issue_number" "$LABEL_PRIORITY_LOW"
  fi

  # Check if reproduction steps are needed for bugs
  if [[ "$category" == "bug" ]]; then
    local needs_repro
    needs_repro=$(needs_reproduction "$body")
    if [[ "$needs_repro" == "true" ]]; then
      apply_label "$issue_number" "$LABEL_NEEDS_REPRO"
      post_comment "$issue_number" "Thanks for opening this issue! 🙏\n\nIt looks like reproduction steps or a minimal code example may be missing. Could you please provide:\n\n1. A minimal, reproducible example\n2. Steps to reproduce the issue\n3. Expected vs actual behavior\n\nThis will help us investigate faster. Thank you!"
    fi
  fi

  log "Triage complete for issue #${issue_number}."
}

# ─── Entry Point ──────────────────────────────────────────────────────────────
main() {
  require_env "GITHUB_TOKEN"
  require_env "ISSUE_NUMBER"

  triage_issue "$ISSUE_NUMBER"
}

main "$@"
