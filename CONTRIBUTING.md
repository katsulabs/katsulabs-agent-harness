# Contributing

## 브랜치

`feature/TB-{id}-{short-name}` · main 직접 커밋 금지 · merge: no-ff

## 흐름

1. `docs/harness/todo.md` 티켓/DoD 확인
2. worktree 또는 feature 브랜치
3. 역할 태그: `[TB-xxx][Contract|Editor|Backend|Frontend|QA]`
4. `validate-harness -Pr` (`.ps1` 또는 `.sh` — `setup-shell.md`)
5. `run-eval` (테스트 설정 시)
6. PR → CI `validate` + `test` green → merge

## 에이전트 규칙

- 상세: `docs/harness/playbook.md`
- 채택: `docs/harness/TEMPLATE.md`
- 확장: `docs/harness/extending.md`

## PR

`.github/PULL_REQUEST_TEMPLATE.md` 필수 섹션을 모두 채운다.
