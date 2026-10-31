---
name: worktree-setup
description: Create or remove one git worktree per ticket so parallel agents never share a checkout. Use when starting a feature ticket or running several agent sessions at once. 병렬 티켓 착수 시 worktree 생성·제거.
disable-model-invocation: true
---

# Worktree Setup

One ticket = one worktree = one agent instance. Sharing a checkout lets parallel agents race on `.git/index` and shared files.

Requires: `git`, `bash`. No other files from the project are needed.

## Create

```bash
bash <skill-dir>/scripts/worktree.sh create TB-101 user-list
# → ../.worktrees/TB-101-user-list on branch feature/TB-101-user-list (from origin/<default branch>)
```

Then work **inside** the printed path. Never commit on the default branch.

## Remove (after merge)

```bash
bash <skill-dir>/scripts/worktree.sh remove TB-101 user-list --delete-branch
```

## List

```bash
bash <skill-dir>/scripts/worktree.sh list
```

## Options (env)

| Variable | Default | Meaning |
|----------|---------|---------|
| `WT_DIR` | `../.worktrees` | where worktrees live |
| `BRANCH_PREFIX` | `feature/` | branch prefix |
| `BASE` | `origin/<default>` | start point |

## Checks the script enforces

- ticket id matches `ABC-123`; short name is lowercase kebab-case
- refuses to reuse an existing path or branch
- adds the worktree directory to `.gitignore` when it is inside the repo

한국어: 티켓당 worktree 1개. 생성 후 출력된 경로 안에서만 작업.
