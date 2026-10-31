# 확장 가이드

globs·역할 표: `AGENTS.md` · `playbook.md` — **여기서 중복하지 않음**.

## eval

`scripts/run-eval`에 프로젝트 테스트 연결. 앱 없으면 harness-smoke.  
**언제 무엇을:** [eval-guide.md](./eval-guide.md)

## CI

`harness-gate.yml` · branch protection: `validate` + `test` · [operations.md](./operations.md)

## MCP

[mcp-setup.md](./mcp-setup.md) — Skills(절차)와 MCP(live API) 분리.

## 서드파티 플러그인

[third-party-plugins.md](./third-party-plugins.md) — Superpowers, gstack, claude-mem, code-review-graph 등 레이어·충돌·채택 절차.

## PR 템플릿

스택에 맞게 테스트 항목 조정. N/A 가능.

## 체크리스트

- [ ] globs 수정 (`presets/` 참고)
- [ ] run-eval 연결
- [ ] MCP (선택)
- [ ] branch protection
