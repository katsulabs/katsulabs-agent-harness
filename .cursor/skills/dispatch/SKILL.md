---
name: dispatch
description: Split a ticket across role-scoped subagents (Contract, Backend, Frontend, QA) with generated prompts, a committed status file, and a PR gate. Use to start multi-agent implementation. 티켓을 역할별 서브에이전트로 분리·조정.
disable-model-invocation: true
---

# Dispatch

Requires: `bash`. `git` optional. Works with any agent that can take a prompt (Cursor Task, Claude Code subagents, etc.).

## Flow

```text
dispatch-plan -> Contract -> (Backend || Frontend) -> QA -> collect-handoff -> PR
```

## 1. Plan

```bash
bash <skill-dir>/scripts/dispatch-plan.sh TB-101
# prints one prompt per role and creates docs/handoffs/TB-101-status.md
bash <skill-dir>/scripts/dispatch-plan.sh TB-101 --dry-run   # print only
```

Single role: `bash <skill-dir>/scripts/dispatch-prompt.sh TB-101 Backend`

## 2. Run the roles

Give each prompt to its own subagent, in this order: Contract first; Backend and Frontend may run in parallel; QA last. One role = one scope; run them in separate worktrees/sessions when they run concurrently (see the `worktree-setup` skill).

To enforce scope at tool-call time in Claude Code, set `HARNESS_ROLE=Backend` for that session if your project installs the harness hooks.

## 3. Track status

Each role updates only its own row in the status file (format: [references/status-schema.md](references/status-schema.md)).

```bash
bash <skill-dir>/scripts/validate-status.sh
```

## 4. PR gate

```bash
bash <skill-dir>/scripts/collect-handoff.sh TB-101
# PASS only when every role is done, 'verified' is filled, and QA is done
```

## Customize

| What | How |
|------|-----|
| Role scopes | `.harness/roles.conf`, e.g. `Backend=src/main/**, services/**` |
| DoD source | `TODO_FILE=path/to/tickets.md` (lines containing the ticket id are quoted) |
| Status dir | `HANDOFF_DIR=...` (default `docs/handoffs`, or `docs/harness/handoffs` if present) |

한국어: Contract → Backend∥Frontend → QA. 역할은 자기 행만 갱신하고, PR 전 `collect-handoff`가 전 역할 done을 확인.
