---
name: pr-workflow
description: Prepare and open a pull request - preflight checks, generated PR body from commits, gh pr create, CI watch. Use only right before opening a PR. PR 생성 전 검증·본문 생성·CI 확인.
disable-model-invocation: true
---

# PR Workflow

Requires: `git`, `bash`. Optional: `gh` (GitHub CLI). Works on any repo.

## Steps

1. **Quality gate first** - run your project gate (the `harness-gate` skill, or your CI-equivalent test command). Do not open a PR on a red gate.
2. **Preflight**

   ```bash
   bash <skill-dir>/scripts/preflight.sh
   ```

   Checks: feature branch, commits ahead, clean tree, pushed, `gh` available/authenticated.
3. **Push**: `git push -u origin "$(git branch --show-current)"`
4. **Generate the body** (sections: Summary, Verification plan, Test gate, Hard gates)

   ```bash
   bash <skill-dir>/scripts/pr-body.sh --tests "npm test: 24 passed" > /tmp/pr-body.md
   # English headings: PR_LANG=en or --lang en
   ```

5. **Open**

   ```bash
   gh pr create --title "TB-101: user list API" --body-file /tmp/pr-body.md
   gh pr checks --watch
   ```

6. Merge only after required checks are green. Prefer a merge commit (`--no-ff`) if your team keeps ticket history.

No `gh`? Paste the generated body into the web UI.

## Body example

```markdown
## 요약

티켓: TB-101

- TB-101 add GET /api/users
- TB-101 users list test

## 검증 계획
...
## 테스트 게이트

npm test: 24 passed
```

한국어: 게이트 → preflight → push → pr-body 생성 → `gh pr create` → CI green 후 머지.
