# katsulabs-agent-harness

**한국어** · [English](#english)

---

## 한국어

AI 코딩 에이전트에게 **누가 · 무엇을 · 어떤 순서로 · 어떤 검증 후** 일할지 알려 주고, 스크립트·CI·에이전트 훅으로 **강제**하는 에이전트 운영 하네스 (3세대).

앱 스타터가 아니고, 에이전트 플랫폼도 아닙니다. 기존 프로젝트에 얹는 **규약 + 검증 번들**입니다. `sample/`은 연습용 mock입니다.

### 무엇이 들어 있나

| 레이어 | 역할 | 위치 |
|--------|------|------|
| Ambient | 짧은 계약 (도구 중립) | `AGENTS.md`, `CLAUDE.md`, `docs/harness/playbook.md` |
| Rules | 역할·경로 범위 | `.cursor/rules/*.mdc`, `scripts/role-scopes.json` |
| Skills | PR·dispatch 등 절차 | `.cursor/skills/*` → `.claude/skills/*` (동기화) |
| Hooks | 호출 **시점** 차단 | `.claude/settings.json`, `scripts/guard-tool.sh`, `scripts/stop-gate.sh` |
| Runtime | 커밋·PR·CI 검증 | `scripts/`, `.githooks/`, `.github/workflows/` |
| Eval | 정적·fixture·실제 LLM 회귀 + 비용 | `eval/`, `scripts/run-llm-ci.sh`, `scripts/llm-cost.sh` |
| MCP | live API (선택) | `docs/harness/mcp-setup.md` |

### 요구 사항

- Git, Bash (macOS / Linux / Git Bash), `jq` (훅·LLM eval), Node 20 (`sample/` 테스트)
- Windows 네이티브: PowerShell 7.4+ (`pwsh`) — [setup-shell.md](docs/harness/setup-shell.md)
- LLM 실호출 eval만 `claude` CLI + `ANTHROPIC_API_KEY`

### 빠른 시작

```bash
git clone https://github.com/katsulabs/katsulabs-agent-harness my-project
cd my-project
./scripts/validate-harness.sh      # 하네스 건강 검사
./scripts/install-githooks.sh      # pre-commit 게이트 설치
./scripts/run-eval.sh              # 앱 테스트 + harness-smoke
```

Windows PowerShell: `pwsh scripts/validate-harness.ps1` 등 동일 이름의 `.ps1`.

### 사용 예제

**1) 티켓 하나를 처음부터 끝까지**

```bash
# docs/harness/todo.md 에 TB-101 등록 후
git worktree add ../.worktrees/TB-101-user-list -b feature/TB-101-user-list
cd ../.worktrees/TB-101-user-list

./scripts/dispatch-plan.sh TB-101        # 전 역할 프롬프트 + 상태 파일 생성
# → 출력된 프롬프트를 역할별 서브에이전트에 전달: Contract → Backend/Frontend → QA
./scripts/collect-handoff.sh TB-101      # 전 역할 done+verified 인지 확인

./scripts/validate-harness.sh -Pr        # PR 직전 게이트
./scripts/summarize-eval.sh              # PR 본문용 eval 요약
```

**2) 역할 범위를 훅으로 강제 (Claude Code)**

```bash
HARNESS_ROLE=Backend claude     # server/** 등만 편집 가능, client/** 편집은 차단
claude                          # 역할 미지정: 범위 검사 없음, 단 main 커밋/푸시는 항상 차단
```

```text
BLOCKED(harness): [Backend] 범위 밖 편집: client/a.js
BLOCKED(harness): main 직접 push 금지 — PR로 머지 (AGENTS.md)
```

**3) 실제 LLM 회귀와 비용 확인**

```bash
./scripts/run-llm-ci.sh --dry-run               # 무료: 파이프라인만 검증
./scripts/run-llm-ci.sh --ids AL-01,AL-03 --budget 0.30
./scripts/llm-cost.sh --max-usd 3               # 누적 토큰·비용, 상한 초과 시 실패
```

**4) 컨텍스트 예산 / 스킬 어댑터**

```bash
./scripts/context-budget.sh        # 상주 문서 토큰 추정, 상한 초과 시 실패
./scripts/sync-adapters.sh         # .cursor/skills 수정 후 .claude/skills 갱신
```

### 학습 순서

| # | 문서 | 내용 |
|---|------|------|
| 1 | [introduction.md](docs/harness/introduction.md) | 하네스 개념 · 레이어 |
| 2 | [evolution.md](docs/harness/evolution.md) | 1·2·3세대 정의 |
| 3 | [how-to-use.md](docs/harness/how-to-use.md) | 경로 A(템플릿) vs B(빈 폴더) |
| 4 | [TEMPLATE.md](docs/harness/TEMPLATE.md) · [bootstrap-prompts.md](docs/harness/bootstrap-prompts.md) | 채택 |
| 5 | [first-ticket.md](docs/harness/first-ticket.md) | 첫 티켓 30분 |
| 6 | [AGENTS.md](AGENTS.md) → [playbook.md](docs/harness/playbook.md) | 계약 · 운영 |
| 7 | [modernization.md](docs/harness/modernization.md) | 도구 중립 · 훅 · 컨텍스트 · LLM eval |

허브: [getting-started.md](docs/harness/getting-started.md) · 전체 스크립트: [scripts-reference.md](docs/harness/scripts-reference.md)

### 멀티에이전트

| 관심사 | 장치 |
|--------|------|
| 동시 실행 안전 | 티켓별 worktree · eval 산출물 `eval/reports/TB-{id}/` |
| 협업 인계 | 커밋되는 상태 채널 `TB-{id}-status.md` (`validate-status`) |
| 작업 조정 | `dispatch-plan` → 역할 병렬 → `collect-handoff` |

상세: [introduction.md](docs/harness/introduction.md) · [status-schema.md](docs/harness/status-schema.md)

### 한계

- Bash 훅 가드는 문자열 휴리스틱입니다. 최후 방어선은 branch protection과 CI입니다.
- 오케스트레이터 서비스·관측 대시보드는 범위 밖입니다 (4세대).
- 라이선스: 상용 라이선스 **초안** — [LICENSE](LICENSE) (영문, 우선) · [LICENSE.ko.md](LICENSE.ko.md) (참고 번역). 법률 검토 전.

---

## English

An operating harness (3rd generation) that tells AI coding agents **who does what, in which order, and after which checks**, and **enforces** it with scripts, CI, and agent hooks.

It is not an app starter and not an agent platform. It is a **convention + verification bundle** you layer onto an existing project. `sample/` is a practice mock.

### What's inside

| Layer | Purpose | Location |
|-------|---------|----------|
| Ambient | Short, tool-neutral contract | `AGENTS.md`, `CLAUDE.md`, `docs/harness/playbook.md` |
| Rules | Role / path scopes | `.cursor/rules/*.mdc`, `scripts/role-scopes.json` |
| Skills | Procedures (PR, dispatch, ...) | `.cursor/skills/*` → `.claude/skills/*` (synced) |
| Hooks | Block **at call time** | `.claude/settings.json`, `scripts/guard-tool.sh`, `scripts/stop-gate.sh` |
| Runtime | Commit / PR / CI checks | `scripts/`, `.githooks/`, `.github/workflows/` |
| Eval | Static, fixture, and real-LLM regression + cost | `eval/`, `scripts/run-llm-ci.sh`, `scripts/llm-cost.sh` |
| MCP | Live APIs (optional) | `docs/harness/mcp-setup.md` |

### Requirements

- Git, Bash (macOS / Linux / Git Bash), `jq` (hooks, LLM eval), Node 20 (for `sample/` tests)
- Native Windows: PowerShell 7.4+ (`pwsh`) — see [setup-shell.md](docs/harness/setup-shell.md)
- Real-LLM eval only: `claude` CLI + `ANTHROPIC_API_KEY`

### Quick start

```bash
git clone https://github.com/katsulabs/katsulabs-agent-harness my-project
cd my-project
./scripts/validate-harness.sh      # harness health check
./scripts/install-githooks.sh      # install pre-commit gate
./scripts/run-eval.sh              # app tests + harness-smoke
```

On Windows PowerShell use the `.ps1` twins, e.g. `pwsh scripts/validate-harness.ps1`.

### Usage examples

**1) One ticket, end to end**

```bash
# after registering TB-101 in docs/harness/todo.md
git worktree add ../.worktrees/TB-101-user-list -b feature/TB-101-user-list
cd ../.worktrees/TB-101-user-list

./scripts/dispatch-plan.sh TB-101        # per-role prompts + status file
# → hand each prompt to a subagent: Contract → Backend/Frontend → QA
./scripts/collect-handoff.sh TB-101      # all roles done + verified?

./scripts/validate-harness.sh -Pr        # pre-PR gate
./scripts/summarize-eval.sh              # eval summary for the PR body
```

**2) Enforce role scope with hooks (Claude Code)**

```bash
HARNESS_ROLE=Backend claude     # may edit server/** etc.; client/** edits are blocked
claude                          # no role: no scope check, but commits/pushes on main are always blocked
```

```text
BLOCKED(harness): [Backend] out-of-scope edit: client/a.js
BLOCKED(harness): direct push to main is forbidden — merge via PR (AGENTS.md)
```

(Actual messages are printed in Korean.)

**3) Real-LLM regression and cost**

```bash
./scripts/run-llm-ci.sh --dry-run               # free: pipeline check only
./scripts/run-llm-ci.sh --ids AL-01,AL-03 --budget 0.30
./scripts/llm-cost.sh --max-usd 3               # cumulative tokens/cost; fails over the cap
```

**4) Context budget / skill adapters**

```bash
./scripts/context-budget.sh        # estimates always-on tokens; fails over budget
./scripts/sync-adapters.sh         # refresh .claude/skills after editing .cursor/skills
```

### Reading order

Start at [introduction.md](docs/harness/introduction.md), then [how-to-use.md](docs/harness/how-to-use.md), [first-ticket.md](docs/harness/first-ticket.md), [AGENTS.md](AGENTS.md), [modernization.md](docs/harness/modernization.md). Hub: [getting-started.md](docs/harness/getting-started.md). All scripts: [scripts-reference.md](docs/harness/scripts-reference.md).

> Docs under `docs/harness/` are written in Korean.

### Limitations

- The Bash hook guard is a string heuristic; branch protection and CI remain the last line of defense.
- No orchestrator service or observability dashboard (generation 4 is out of scope).
- License: commercial license **draft**, not yet reviewed by counsel — see [LICENSE](LICENSE) (controlling) and [LICENSE.ko.md](LICENSE.ko.md) (reference translation).
