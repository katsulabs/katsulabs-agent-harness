---
name: harness-gate
description: Run a pre-PR quality gate on any git repo - not on default branch, commits ahead, ticket id in commit subjects, clean tree, tests pass. Use right before opening a PR. PR 직전 품질 게이트.
disable-model-invocation: true
---

# Harness Gate

Requires: `git`, `bash`, and whatever test runner your project already uses. Nothing else.

## Run

```bash
bash <skill-dir>/scripts/gate.sh
```

Example output:

```text
gate: branch=feature/TB-101-user-list base=origin/main
  ok    branch 'feature/TB-101-user-list' is not 'main'
  ok    2 commit(s) ahead of origin/main
  ok    all commit subjects carry a ticket id ([A-Za-z]+-[0-9]+)
  ok    working tree clean
  ok    tests: npm test
PASS: gate (0 warning(s))
```

## Checks

| # | Check | Fails when |
|---|-------|-----------|
| 1 | branch | you are on the default branch |
| 2 | commits | nothing ahead of base |
| 3 | commit subjects | a subject has no ticket id |
| 4 | working tree | uncommitted changes |
| 5 | project validator | `scripts/validate-harness.sh -Pr` exists and fails (full harness only) |
| 6 | tests | auto-detected test command fails (npm, gradle, maven, go, cargo, pytest, make) |

No test command found is a warning, not a failure. Set `TEST_CMD="..."` to be explicit.

## Options (env)

| Variable | Default | Meaning |
|----------|---------|---------|
| `TICKET_PATTERN` | `[A-Za-z]+-[0-9]+` | regex a commit subject must match (e.g. `TB-[0-9]+`) |
| `BASE` | `origin/<default>` | comparison ref |
| `TEST_CMD` | auto | test command |
| `SKIP_TESTS=1` / `--no-tests` | off | skip tests |

## After it passes (manual)

PR description matches the diff; any skipped check has a written reason.

한국어: PR 직전 실행. 기본 브랜치 아님 · 커밋 있음 · 커밋에 티켓 ID · 작업트리 깨끗 · 테스트 통과.
