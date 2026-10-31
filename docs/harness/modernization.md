# 하네스 현대화 (TB-029)

3세대 하네스를 최근 에이전트 운영 트렌드에 맞춘 4축 개선. 레이어 표는 [introduction.md](./introduction.md), 세대 정의는 [evolution.md](./evolution.md).

| 축 | 문제 | 해결 | 위치 |
|----|------|------|------|
| 도구 중립 | 규칙·스킬·훅이 `.cursor/**` 전용 | `AGENTS.md` 단일 진실 + 얇은 어댑터 | `CLAUDE.md`, `.claude/`, `sync-adapters` |
| 실행 시점 강제 | githooks·CI는 **사후** 차단 | 에이전트 훅(PreToolUse/Stop)으로 **호출 시점** 차단 | `guard-tool`, `stop-gate`, `role-scopes.json` |
| 컨텍스트 슬림 | 상주 문서 증가 → 토큰·준수율 저하 | 상주 예산 측정·상한 게이트, playbook 슬림화 | `context-budget` |
| 실제 LLM eval | fixture만 자동, 비용 불투명 | 헤드리스 `claude -p` 회귀 + 토큰/비용 기록·상한 | `run-llm-ci`, `llm-cost`, `llm-eval.yml` |

## 1. 도구 중립

- 계약은 `AGENTS.md` 하나. `CLAUDE.md`는 `@AGENTS.md`를 import하고 Claude 전용 사항만 추가.
- 스킬 원본은 `.cursor/skills/<name>/SKILL.md`. `.claude/skills/`는 `./scripts/sync-adapters.sh`가 복사 생성 (심볼릭 링크는 Windows에서 깨져 복사 방식).
- 불일치는 `validate-harness`가 `ADAPTER:`로 실패시킨다. `--check`로 쓰기 없이 검사.
- 역할 범위의 단일 출처: `scripts/role-scopes.json` (훅이 읽음). `AGENTS.md`·`.mdc` globs와의 동기는 기존 `SCOPE_SYNC`가 계속 검사.

## 2. 에이전트 훅 강제

`.claude/settings.json`이 등록:

| 훅 | 스크립트 | 동작 |
|----|----------|------|
| PreToolUse (Bash) | `guard-tool.sh` | `main`에서 commit/merge/rebase 차단 · main 대상 push 차단 · force push 차단 |
| PreToolUse (Edit/Write 등) | `guard-tool.sh` | `HARNESS_ROLE` 지정 시 해당 역할 globs 밖 편집 차단 |
| Stop | `stop-gate.sh` | 종료 전 `validate-harness` 실패 시 재개 유도 (`stop_hook_active`로 무한 루프 방지) |

규약:

- 차단은 exit code 2 + stderr 메시지 (Claude Code 훅 규약). `HARNESS_ROLE` 미설정(메인 세션)은 범위 검사 통과.
- 서브에이전트 디스패치 시 역할을 환경변수로 전달: `HARNESS_ROLE=Backend claude ...`.
- **한계:** Bash 가드는 문자열 휴리스틱이다. 따옴표·heredoc 안의 `git push --force` 같은 텍스트도 오탐할 수 있고, `sh -c` 등 우회는 못 막는다. 최후 방어선은 여전히 branch protection·CI. 테스트: `eval/guard-tool.test.sh`.
- Cursor 훅(`.cursor/hooks.json`)은 기존 stop 훅 유지. PreToolUse 대응은 미구현.

## 3. 컨텍스트 슬림

- `./scripts/context-budget.sh` — 상주 문서(`AGENTS.md`, `CLAUDE.md`, `orchestrator.mdc`)와 `playbook.md`의 근사 토큰(바이트/3, 한글 보수적)을 측정. 기본 상한: 상주 합계 1500, playbook 1700 (`BUDGET_ALWAYS`/`BUDGET_PLAYBOOK` 환경변수로 조정).
- 초과하면 `validate-harness`가 `CONTEXT_BUDGET:`으로 실패.
- playbook에서 다른 문서와 중복되던 섹션(샘플 앱·레이어·샘플·표기·운영 게이트 표)을 포인터로 축약. 상세는 점진적 공개(필요할 때만 링크 문서 로드).
- 추정치이며 실제 토크나이저 값이 아님. 추세 감시용.

## 4. 실제 LLM eval + 비용

```bash
./scripts/run-llm-ci.sh --dry-run             # 무료: fixture 응답으로 파이프라인만 검증 (harness-smoke에 포함)
./scripts/run-llm-ci.sh --ids AL-01,AL-03     # 실호출: claude -p (plan 모드, 태스크당 --budget USD 상한)
./scripts/llm-cost.sh --max-usd 3             # 누적 비용 집계·상한
```

- 프롬프트는 `eval/agent-tasks/harness-baseline.md`, 채점 규칙은 `eval/agent-tasks/expected/al-*.json`(`must`/`must_not`/`must_any`)을 재사용 — 수동 세션과 같은 기준.
- 리포트: `eval/reports/llm-run-<UTC>.json`, `latest-llm-run.json` (입력·출력 토큰, `cost_usd`, 태스크별 결과). 커밋하지 않음(.gitignore).
- CI: `.github/workflows/llm-eval.yml` — 수동 실행 + 주간 스케줄, `ANTHROPIC_API_KEY` secret 필요. PR 게이트(`harness-gate`)와 분리해 비용 통제. 총비용 상한 초과 시 실패.
- 현재 자동화 대상은 단일 프롬프트로 채점 가능한 태스크(AL-01·03·04 기본). `/claude` 라우팅 태스크(AL-06~14)는 도구 실행 흐름 검증이 필요해 수동 유지.
- 기존 `cost-summary`(스크립트 소요 시간 추정)와 별개 — 실제 토큰/비용은 `llm-cost`.

## 5. 스킬 단독 패키지

`.cursor/skills/*` 6개는 저장소 없이도 동작하도록 각자 `scripts/`·`references/`를 포함한다 (bash + git만 필요, 프로젝트 스택 무관).

| 스킬 | 포함 스크립트 |
|------|---------------|
| worktree-setup | `worktree.sh` (create/remove/list) |
| harness-gate | `gate.sh` (브랜치·커밋·티켓ID·깨끗함·테스트 자동 감지) |
| pr-workflow | `preflight.sh`, `pr-body.sh` |
| contract-handoff | `new-handoff.sh`, `validate-handoff.sh` (+ 스키마) |
| backend-test-gate | `test-gate.sh` (러너 자동 감지, PR용 결과 한 줄) |
| dispatch | `dispatch-plan/prompt.sh`, `collect-handoff.sh`, `validate-status.sh` (+ 스키마) |

- 설정은 환경변수(`TICKET_PATTERN`, `TEST_CMD`, `BACKEND_PATHS`, `HANDOFF_DIR`…)와 `.harness/roles.conf`로 하며 각 `SKILL.md`에 표로 정리.
- 검증: `eval/skills-standalone.test.sh` — 스킬 폴더만 임시 위치로 복사해 **빈 git repo**(origin 포함)에서 실행. harness-smoke에 포함.
- 배포: `./scripts/package-skills.sh` → `dist/skills/<name>.zip` (LICENSE 동봉, 테스트 통과 필수).
- 저장소 루트 `scripts/*`(전체 하네스용)와 일부 로직이 중복된다. 스킬 쪽이 이식성 위주의 경량판이다.
- 스킬 본문은 영어(+한국어 한 줄). 스킬 동작에는 `jq`·`pwsh`가 필요 없다.

## 의존성·플랫폼

신규 스크립트는 **bash + jq** (ps1 쌍 없음). Windows는 Git Bash + jq. 기존 `.ps1`/`.sh` 쌍 규약의 예외이며, `validate-harness.ps1`은 필수 파일 존재와 어댑터 동기만 검사한다.

## 범위 밖

플랫폼화(상시 오케스트레이터 서비스, 트레이스 수집 대시보드)와 Cursor PreToolUse 훅은 다루지 않음. 필요 시 [evolution.md](./evolution.md) 4세대 항목 참고.
