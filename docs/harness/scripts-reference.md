# 스크립트 참조

일상은 `AGENTS.md` **Daily / PR** 만으로 충분. 전체 목록·용도.

| 스크립트 | 시점 | 용도 |
|----------|------|------|
| `validate-harness` | 커밋·CI | 문서·규칙·필수 파일 |
| `validate-harness -Pr` | PR 직전 | + dispatch · todo · commit-msg |
| `run-eval` | 티켓·CI | 앱/sample 테스트 + harness-smoke |
| `validate-handoff` | handoff 변경 | frontmatter·섹션 |
| `validate-status` | 상태 채널 변경 | frontmatter·역할 상태 표 |
| `validate-staged-handoff` | pre-commit | staged handoff만 |
| `dispatch-plan` | 티켓 착수 | 전 역할 프롬프트 + 상태 스켈레톤 |
| `dispatch-prompt` | 티켓 착수 | 역할별 단건 프롬프트 |
| `collect-handoff` | PR 전 | 전 역할 `done`+`verified` 게이트 |
| `verify-dispatch` | PR | `feature/TB-{id}-*` 브랜치 |
| `validate-todo-sync` | PR | 브랜치 ↔ todo.md |
| `validate-commit-msg -Pr` | PR | 커밋에 TB-{id} |
| `validate-pr-body` | PR (선택) | 본문 필수 섹션 |
| `summarize-eval` | PR | eval Markdown 요약 |
| `run-agent-eval` | harness-smoke | 정적 agent 프록시 |
| `run-agent-llm-eval` | 릴리스 전 | LLM 세션 템플릿·채점 |
| `score-agent-llm` | 릴리스 전 | 응답 패턴 채점 |
| `cost-summary` | PR (선택) | duration 집계 |
| `install-githooks` | 채택 1회 | pre-commit |
| `guard-tool` | 에이전트 훅 | main 커밋/푸시·범위 밖 편집 차단 (bash+jq) |
| `stop-gate` | 에이전트 훅 | 종료 전 validate-harness |
| `sync-adapters` | skills 변경 후 | `.cursor/skills` → `.claude/skills` (`--check`) |
| `context-budget` | 문서 변경 후·CI | 상주 컨텍스트 토큰 예산 |
| `run-llm-ci` | 릴리스 전·주간 | 헤드리스 `claude -p` 회귀 + 토큰/비용 (`--dry-run` 무료) |
| `llm-cost` | `run-llm-ci` 후 | 토큰·비용 집계·상한 |
| `export-release` | 배포 시 | 히스토리 없는 새 저장소 폴더 생성 (내부 기록 제거·이름 변경·todo/alignment-log 초기화) |
| `package-skills` | 배포 시 | 스킬 6개를 단독 동작 테스트 후 `dist/skills/<name>.zip`으로 패키징 |

`.ps1` / `.sh` 쌍 동일 (단, 에이전트 훅·LLM CI 신규 스크립트는 bash+jq 전용 — [modernization.md](./modernization.md)). 쉘: `setup-shell.md`
