# AGENTS.md

<!-- 프로젝트 채택 시 [대괄호]를 실제 값으로 교체 -->

## 프로젝트

- **이름**: [프로젝트명]
- **스택**: [예: Node/React, Spring/Vue, monorepo]
- **구조**: [예: backend=server/, frontend=client/]

## 에이전트 계약

| 항목 | 값 |
|------|-----|
| 운영 참조 | `docs/harness/playbook.md` (필요 섹션만) |
| 티켓 | `docs/harness/todo.md` |
| 브랜치 | `feature/TB-{id}-{short-name}` |
| 머지 | no-ff · main 직접 커밋 금지 |

## 역할·경로

| Agent | 경로 |
|-------|------|
| Editor | `docs/**`, `.cursor/**`, `.github/**` |
| Contract | `db/**`, `**/dto/**`, `**/openapi.*`, `contracts/**`, `api-spec/**` |
| Backend | `modules/**`, `backend/**`, `server/**`, `api/**` |
| Frontend | `frontend/**`, `client/**`, `apps/web/**` |

globs는 `.cursor/rules/*.mdc`와 동기화. Claude Code: `CLAUDE.md` + 훅(`HARNESS_ROLE`로 범위 강제) — `docs/harness/modernization.md`

## 검증 — Daily (티켓)

PowerShell **7.4+** (`pwsh`). 쉘: `docs/harness/setup-shell.md`

```powershell
pwsh scripts/dispatch-prompt.ps1 -Ticket TB-xxx -Role Backend
pwsh scripts/run-eval.ps1
pwsh scripts/validate-handoff.ps1    # handoff 변경 시만
```

## 검증 — PR 직전

```powershell
pwsh scripts/validate-harness.ps1 -Pr
pwsh scripts/summarize-eval.ps1 -OutFile eval/reports/pr-eval-summary.md
```

## 검증 — Advanced (선택)

릴리스 전·규칙 대变更: `docs/harness/eval-guide.md` 참고.

```powershell
pwsh scripts/run-agent-llm-eval.ps1
pwsh scripts/score-agent-llm.ps1 -Fixture
pwsh scripts/cost-summary.ps1
```

**전체 스크립트:** `docs/harness/scripts-reference.md`

macOS / Linux: `scripts/*.sh` 동일 이름.

```bash
./scripts/validate-harness.sh
./scripts/run-eval.sh
./scripts/validate-harness.sh -Pr
./scripts/install-githooks.sh
```

## MCP (선택)

`docs/harness/mcp-setup.md`

## 금지

- 요청 범위 밖 diff
- main 직접 push
- 검증 없이 PR 생성
- 같은 워킹트리를 여러 인스턴스가 동시 사용 (병렬은 티켓별 worktree — `playbook.md` 동시 실행 규칙)
- 남 티켓 브랜치의 `todo.md` 행 편집
