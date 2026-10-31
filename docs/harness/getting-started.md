# 시작 (허브)

**학습은 루트 [README.md](../../README.md)에서 시작한다.**  
이 문서는 읽기 순서만 모은다. 개념 상세는 [introduction.md](./introduction.md)에만 둔다.

---

## 학습 순서

| # | 문서 | 내용 |
|---|------|------|
| 0 | [README.md](../../README.md) | 저장소 입구 · 30초 오리엔테이션 |
| 1 | [introduction.md](./introduction.md) | 하네스가 뭔지 · 3세대 레이어 |
| 2 | [evolution.md](./evolution.md) | 1·2·3세대 정의 |
| 3 | [how-to-use.md](./how-to-use.md) | 경로 A(템플릿) vs B(빈 폴더) |
| 4a | [TEMPLATE.md](./TEMPLATE.md) | **경로 A** — clone/템플릿 채택 |
| 4b | [bootstrap-prompts.md](./bootstrap-prompts.md) | **경로 B** — 빈 폴더 생성 프롬프트 |
| 5 | [first-ticket.md](./first-ticket.md) | 첫 티켓 30분 |
| 6 | [AGENTS.md](../../AGENTS.md) | 에이전트 계약·검증 명령 |
| 7 | [playbook.md](./playbook.md) | 운영 — **필요 섹션만** |

경로 A면 4b 스킵. 경로 B면 4a 대신 4b.

---

## Day 1 체크

```powershell
pwsh scripts/validate-harness.ps1
pwsh scripts/install-githooks.ps1
pwsh scripts/run-eval.ps1
```

GitHub: CI `validate` + `test` · [operations.md](./operations.md)

---

## 더 보기 (필요할 때)

| 문서 | 언제 |
|------|------|
| [glossary.md](./glossary.md) | 용어 |
| [scripts-reference.md](./scripts-reference.md) | 스크립트 전체 |
| [eval-guide.md](./eval-guide.md) | Eval |
| [extending.md](./extending.md) · [mcp-setup.md](./mcp-setup.md) | 확장 |
| [third-party-plugins.md](./third-party-plugins.md) | Superpowers·CRG 등 서드파티 |
| [examples/](./examples/) | 샘플 |

문서 목록: [README.md](./README.md) (인덱스)
