# PR Review Skill

This skill automates pull request review by analyzing code changes, checking for common issues, and providing structured feedback.

## Overview

The PR Review skill performs the following tasks:
1. Fetches the diff of a pull request
2. Analyzes changed files for code quality issues
3. Checks for test coverage on new/modified code
4. Verifies documentation is updated when public APIs change
5. Posts a structured review comment summarizing findings

## Usage

This skill is triggered automatically on pull request creation or update events, or can be invoked manually.

### Inputs

| Variable | Description | Required |
|----------|-------------|----------|
| `PR_NUMBER` | The pull request number to review | Yes |
| `GITHUB_TOKEN` | GitHub token with PR read/write access | Yes |
| `REPO` | Repository in `owner/repo` format | Yes |
| `OPENAI_API_KEY` | OpenAI API key for AI-assisted review | No |

### Outputs

The skill posts a review comment to the pull request with:
- Summary of changes
- Identified issues (errors, warnings, suggestions)
- Test coverage assessment
- Documentation completeness check

## Configuration

Customize behavior via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `REVIEW_LEVEL` | `standard` | One of `minimal`, `standard`, `thorough` |
| `POST_COMMENT` | `true` | Whether to post the review as a PR comment |
| `FAIL_ON_ERRORS` | `false` | Exit with non-zero code if errors are found |
| `IGNORE_PATTERNS` | `` | Comma-separated glob patterns to ignore |

## Review Checklist

The skill evaluates each changed file against:

### Code Quality
- [ ] No syntax errors or linting violations
- [ ] Functions/methods have appropriate docstrings
- [ ] No hardcoded secrets or credentials
- [ ] Error handling is present where appropriate
- [ ] No obvious performance anti-patterns

### Testing
- [ ] New functions have corresponding tests
- [ ] Modified logic has updated test cases
- [ ] Tests are meaningful (not just coverage padding)

### Documentation
- [ ] Public API changes reflected in docs
- [ ] CHANGELOG updated for user-facing changes
- [ ] README updated if setup/usage changes

## Examples

```bash
# Run manually against a specific PR
PR_NUMBER=42 GITHUB_TOKEN=ghp_xxx REPO=org/repo bash .agents/skills/pr-review/scripts/run.sh
```

## Notes

- The skill respects `.gitignore` and will not review ignored files
- Binary files are skipped automatically
- Large diffs (>500 files) are summarized rather than reviewed line-by-line
