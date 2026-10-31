---
name: backend-test-gate
description: After changing server/backend/api code, detect the project's test runner, run it, and produce a PR-ready test result line; warns when API/DTO/DB files changed without a handoff update. 백엔드 변경 후 테스트 게이트.
disable-model-invocation: true
---

# Backend Test Gate

Requires: `git`, `bash`, and your project's own test runner (auto-detected: npm, gradle, maven, go, cargo, pytest, make).

## Run

```bash
bash <skill-dir>/scripts/test-gate.sh
```

```text
test-gate: base=origin/main paths=[modules backend server api]
backend paths changed: server
running: npm test
PASS: test-gate
PR line: Backend test gate: PASS (npm test)
```

Paste the `PR line:` into the PR's test-gate section.

## Behavior

- Looks at files changed against the base branch plus uncommitted/untracked files.
- No file under the backend paths changed: `SKIP` (exit 0). `--force` runs tests anyway.
- If API spec, DTO, contract or migration files changed and no handoff doc changed, it prints a `WARN` - update the contract handoff (`contract-handoff` skill).
- No test command found: `FAIL` with a hint to set `TEST_CMD`.

## Options (env)

| Variable | Default | Meaning |
|----------|---------|---------|
| `BACKEND_PATHS` | `modules backend server api` | directories counted as backend (space-separated) |
| `TEST_CMD` | auto | explicit test command |
| `BASE` | `origin/<default>` | comparison ref |

Examples: `BACKEND_PATHS="src/main services" bash scripts/test-gate.sh` · `TEST_CMD="pytest -q tests/api" bash scripts/test-gate.sh --force`

한국어: server/backend/api 변경 시 실행. 테스트 러너를 자동 감지하고 PR 본문용 결과 한 줄을 출력.
