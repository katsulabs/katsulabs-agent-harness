# 첫 티켓 30분 가이드

입구: [introduction.md](./introduction.md) · Eval: [eval-guide.md](./eval-guide.md)

하네스 채택 후 첫 기능 티켓을 끝까지 밟는 최소 경로.

## 0–5분: 준비

```powershell
pwsh scripts/validate-harness.ps1
pwsh scripts/install-githooks.ps1
```

`AGENTS.md` [대괄호] 채우기 · `docs/harness/presets/` 에서 스택 선택

## 5–10분: 티켓

`docs/harness/todo.md` 활성에 TB-102 등록 + DoD 1줄

```bash
git worktree add ../.worktrees/TB-102-feature -b feature/TB-102-feature
```

## 10–15분: Contract

```
[TB-102][Contract] ...
```

스킬 `contract-handoff` · `validate-handoff` PASS

## 15–25분: 구현

```
pwsh scripts/dispatch-prompt.ps1 -Ticket TB-102 -Role Backend
```

`run-eval` · 필요 시 스킬 `backend-test-gate`

## 25–30분: PR

```
pwsh scripts/validate-harness.ps1 -Pr
pwsh scripts/run-eval.ps1
pwsh scripts/summarize-eval.ps1 -OutFile eval/reports/pr-eval-summary.md
```

PR 본문: 템플릿 + eval 요약 · `validate-pr-body` (선택)

실패 시: `playbook.md` **실패 시** 섹션 참고.
