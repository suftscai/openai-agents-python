# Issue Triage Skill

This skill automatically triages new GitHub issues by analyzing their content, applying appropriate labels, assigning priority, and providing an initial response to the issue author.

## What It Does

1. **Analyzes issue content** — Reads the issue title, body, and any attached code/logs
2. **Classifies issue type** — Bug report, feature request, question, documentation, or other
3. **Assigns labels** — Applies relevant labels based on content analysis
4. **Sets priority** — Determines priority (critical, high, medium, low) based on impact signals
5. **Checks for duplicates** — Searches existing issues for potential duplicates
6. **Posts initial response** — Leaves a helpful comment acknowledging the issue and requesting any missing information

## Trigger

This skill runs when:
- A new issue is opened
- An issue is reopened
- Manually triggered via workflow dispatch

## Labels Applied

### Type Labels
- `bug` — Something is not working as expected
- `enhancement` — New feature or request
- `question` — Further information is requested
- `documentation` — Improvements or additions to documentation
- `duplicate` — This issue or pull request already exists

### Priority Labels
- `priority: critical` — System is unusable, data loss, security vulnerability
- `priority: high` — Major functionality broken, no workaround
- `priority: medium` — Functionality impaired but workaround exists
- `priority: low` — Minor inconvenience or cosmetic issue

### Component Labels
- `component: agents` — Related to agent execution or lifecycle
- `component: tools` — Related to tool definitions or execution
- `component: tracing` — Related to tracing or observability
- `component: streaming` — Related to streaming responses
- `component: handoffs` — Related to agent handoff functionality
- `component: guardrails` — Related to input/output guardrails
- `component: memory` — Related to memory or context management

## Missing Information Checklist

The skill will request the following if not provided:

- [ ] Python version
- [ ] `openai-agents` package version
- [ ] Minimal reproducible example
- [ ] Full error traceback (for bugs)
- [ ] Expected vs actual behavior (for bugs)
- [ ] Use case description (for feature requests)

## Configuration

The skill can be configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `TRIAGE_AUTO_LABEL` | `true` | Automatically apply labels |
| `TRIAGE_AUTO_COMMENT` | `true` | Post initial response comment |
| `TRIAGE_DUPLICATE_THRESHOLD` | `0.85` | Similarity threshold for duplicate detection |
| `TRIAGE_ASSIGN_MAINTAINER` | `false` | Auto-assign to a maintainer |

## Agent

Uses the OpenAI Agents SDK with `gpt-4o` to perform semantic analysis of issue content.
