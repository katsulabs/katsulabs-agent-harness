# Multi-agent 실행 예시 — dispatch-plan → collect-handoff

**실제 다중 인스턴스(티켓별 worktree)**로 오케스트레이션 흐름을 end-to-end 재현하는 walkthrough.

개념: [introduction.md](../introduction.md) 멀티에이전트 섹션 · 상태 스키마: [status-schema.md](../status-schema.md) · 명령 프롬프트: [multi-agent-dispatch.md](./multi-agent-dispatch.md)

> 아래 `TB-900`/`TB-901`은 데모용 가짜 티켓이다. 실제 티켓은 `todo.md`에 등록된 것을 쓴다.

---

## 0. 모델

**다중 인스턴스 = 티켓별 git worktree** (`1 워킹트리 = 1 인스턴스`). 각 인스턴스는 자기 체크아웃·자기 브랜치·자기 `eval/reports/TB-{id}/`를 가져 파일 경쟁이 없다.

```text
main                          [main]
../.worktrees/TB-900-demo     [feature/TB-900-demo]   ← 인스턴스 A
../.worktrees/TB-901-demo     [feature/TB-901-demo]   ← 인스턴스 B
```

---

## 1. 인스턴스(worktree) 생성

```bash
git fetch origin main
git worktree add ../.worktrees/TB-900-demo -b feature/TB-900-demo main
git worktree add ../.worktrees/TB-901-demo -b feature/TB-901-demo main
git worktree list
```

---

## 2. 각 인스턴스에서 `dispatch-plan`

전 역할(Contract → Backend ∥ Frontend → QA) 프롬프트 + 상태 스켈레톤을 한 번에 생성한다.

```bash
# 인스턴스 A
cd ../.worktrees/TB-900-demo
./scripts/dispatch-plan.sh TB-900
```

```text
흐름: Contract → Backend ∥ Frontend → QA
상태 채널: docs/harness/handoffs/TB-900-status.md (스키마: docs/harness/status-schema.md)
PR 전 게이트: ./scripts/collect-handoff.sh TB-900
CREATED: docs/harness/handoffs/TB-900-status.md
PASS: dispatch-plan (TB-900)
```

생성된 스켈레톤(전 역할 `todo`):

```markdown
---
ticket: TB-900
updated: 2026-07-19
---

# Status — TB-900

| role | status | artifacts | verified |
|------|--------|-----------|----------|
| Contract | todo | — | — |
| Backend | todo | — | — |
| Frontend | todo | — | — |
| QA | todo | — | — |
```

> 미리보기만 필요하면 `./scripts/dispatch-plan.sh TB-900 --dry-run` (파일 미기록).

---

## 3. eval 산출물 격리 확인

각 인스턴스에서 `run-agent-eval`을 돌리면 리포트가 티켓 경로로 분리된다 — 동시 실행해도 클로버 없음.

```bash
# 인스턴스 A → eval/reports/TB-900/latest-agent-eval.json
# 인스턴스 B → eval/reports/TB-901/latest-agent-eval.json
```

---

## 4. 역할 진행 + `collect-handoff` 게이트

각 역할은 종료 시 상태 파일의 **자기 행만** `done`으로 갱신하고 `artifacts`·`verified`를 기록한다(append-only). PR 전 게이트 `collect-handoff`는 미완 역할을 정확히 짚으며 전 역할 `done`일 때만 통과한다.

| 단계 | 상태 | `collect-handoff` |
|------|------|-------------------|
| dispatch-plan 직후 | 전 역할 `todo` | ❌ FAIL (5 issues) |
| Contract `done` | BE/FE/QA 대기 | ❌ FAIL (4 issues) |
| Backend ∥ Frontend `done` | QA 대기 | ❌ FAIL (2 issues) |
| QA `done` | **전 역할 done** | ✅ **PASS** (4 roles done) |

완료된 상태 파일:

```markdown
| role | status | artifacts | verified |
|------|--------|-----------|----------|
| Contract | done | docs/harness/handoffs/TB-900-handoff.md | validate-handoff PASS |
| Backend | done | server/users.js | run-eval PASS |
| Frontend | done | client/user-list.html | run-eval PASS |
| QA | done | eval/reports/pr-eval-summary.md | validate-harness -Pr PASS |
```

```bash
./scripts/collect-handoff.sh TB-900
# PASS: collect-handoff (docs/harness/handoffs/TB-900-status.md · 4 roles done)
```

QA는 이 PASS 이후 `validate-harness -Pr` → PR로 진행한다.

---

## 5. 정리

```bash
git worktree remove ../.worktrees/TB-900-demo --force
git worktree remove ../.worktrees/TB-901-demo --force
git branch -D feature/TB-900-demo feature/TB-901-demo
git worktree prune
```

---

## 요점

| 관심사 | 이 예시에서 확인 |
|--------|------------------|
| 동시 실행 안전 | worktree별 격리 + `eval/reports/TB-{id}/` 분리 → 경쟁 없음 |
| 협업 인계 | 커밋되는 상태 파일로 "구두 전달" 없이 역할 진행 공유 |
| 작업 조정 | `dispatch-plan`(분배) → `collect-handoff`(수렴 게이트) |

Windows: 스크립트 `.sh` → `.ps1`, 예) `pwsh scripts/dispatch-plan.ps1 -Ticket TB-900` · `pwsh scripts/collect-handoff.ps1 -Ticket TB-900`.
