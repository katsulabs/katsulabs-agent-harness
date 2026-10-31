# Bootstrap 프롬프트 — 빈 폴더에서 n세대 하네스 생성

**경로 B**용. 빈 디렉터리에서 Cursor에 붙여 넣어 **1·2·3세대** 하네스를 처음부터 만든다.  
정의: [evolution.md](./evolution.md) · 경로 선택: [how-to-use.md](./how-to-use.md)

이 템플릿의 목표는 **3세대**. 4세대(플랫폼)는 범위 밖 — 프롬프트 없음.

---

## 사용법

1. 아래 표에서 세대 선택 (보통 **3세대**)
2. 해당 절의 프롬프트 **전체** 복사
3. 맨 아래 `[내 프로젝트]`만 채우기
4. **빈 폴더**를 Cursor로 연 뒤 붙여넣기
5. 생성 후 안내에 따라 검증 → `git init` → remote push

사용자는 티켓 번호·git 이력을 몰라도 된다. 프로젝트 4줄만 채운다.

```text
[내 프로젝트]
- 이름:
- 스택:
- 폴더:          # 예: server/, client/
- 원하는 세대:   # 1 | 2 | 3
```

| 세대 | 한 줄 | 강제력 | 언제 |
|------|--------|--------|------|
| **1** | 규칙 텍스트 1파일 | 없음 | 개인 실험 |
| **2** | Rules + 문서 | 권고 | 역할 분리는 필요, 검증 자동화는 아직 |
| **3** | Ambient + Rules + Skills + Runtime (+ MCP) | 스크립트·CI·hooks | **권장** — 이 템플릿 수준 |

---

## 1세대 — 프롬프트 엔지니어링

> 규칙이 **말로만** 존재. 역할 분리·검증 스크립트 없음.

```
당신은 Cursor 에이전트 하네스 구축 에이전트입니다.
빈 폴더에 **1세대** 하네스만 만드세요.

## 세대 정의
- 규칙이 텍스트 한 파일(또는 긴 시스템 프롬프트)에만 존재
- 검증·CI·역할별 globs 없음
- “main에 커밋하지 마”, “테스트 돌려” 등은 말로만 적음

## 만들 파일 (2개만)
.cursorrules     ← 모든 규칙 (또는 .cursor/rules 단일 파일 1개)
README.md        ← “1세대 — 검증 없음” 한 줄 포함

## .cursorrules에 넣을 내용
1. 프로젝트 한 줄 설명
2. 코딩 스타일: 기존 컨벤션, 최소 diff
3. 금지: main 직접 커밋, 요청 범위 밖 수정
4. 권고: 작업 전 테스트, PR 전 self-review
5. 스택·폴더 구조 ([내 프로젝트] 참고)

## 만들지 말 것
- 역할별 .mdc 여러 개
- AGENTS.md, playbook, todo 티켓 체계
- scripts/, CI, githooks, Skills, handoff

## 완료 후
- git init → 첫 커밋
- README 말미: 역할 분리 필요 시 2세대, 검증 자동화 필요 시 3세대로 업그레이드

[내 프로젝트]
- 이름:
- 스택:
- 폴더:
- 원하는 세대: 1
```

---

## 2세대 — 구조화된 규약

> Rules + 문서. 역할·경로는 나누지만 **시스템이 막지는 않음**.

```
당신은 Cursor 에이전트 하네스 구축 에이전트입니다.
빈 폴더에 **2세대** 하네스를 만드세요. Runtime(스크립트·CI)은 넣지 마세요.

## 세대 정의
- .cursor/rules/*.mdc — 역할·경로별 조건부 규칙
- AGENTS.md, playbook.md — 운영 계약 문서화
- 규칙 준수는 사람·에이전트 재량 (검증 스크립트 없음)

## 디렉터리 구조
.
├── .cursor/rules/
│   ├── orchestrator.mdc    # alwaysApply: true — 짧게, playbook 링크만
│   ├── editor.mdc
│   ├── contract.mdc
│   ├── backend.mdc
│   ├── frontend.mdc
│   └── qa.mdc
├── AGENTS.md
├── docs/harness/
│   ├── playbook.md
│   ├── todo.md
│   ├── glossary.md
│   └── getting-started.md
├── .github/PULL_REQUEST_TEMPLATE.md
└── README.md

## orchestrator.mdc 핵심
- playbook: docs/harness/playbook.md
- main 직접 커밋 금지
- 기능 브랜치: feature/티켓번호-짧은이름
- 구현 요청 시: todo 확인 → 역할 태그로 작업 분리
- 질문만 할 때: 파일 읽기·디스패치 생략

## 역할·경로 ([내 프로젝트] 폴더에 맞게 globs 조정)
| 역할 | 담당 범위 |
|------|----------|
| Editor | docs, .cursor, .github |
| Contract | API 스펙, DTO, DB, contracts |
| Backend | server, api, backend |
| Frontend | client, frontend, apps/web |
| QA | 검수·PR (문서로만 정의) |

## playbook.md 필수
1. 역할 표
2. 흐름: todo → 브랜치 → 계약 → 서버/UI → 검수 → PR
3. worktree: ../.worktrees/티켓번호-이름 (병렬 시)

## 만들지 말 것
- scripts/ (validate-harness, run-eval 등)
- .cursor/skills/
- 하네스 CI workflow, githooks
- handoff 린터, eval runner

## 완료 후
- todo.md에 첫 항목 1행
- README: “2세대 — 권고만, 강제 없음. 검증 자동화는 3세대”
- git init → feature 브랜치에서 첫 커밋

[내 프로젝트]
- 이름:
- 스택:
- 폴더:
- 원하는 세대: 2
```

---

## 3세대 — 운영 하네스 (이 템플릿 목표)

> Ambient + Rules + Skills + Runtime (+ MCP 선택).  
> 규칙 실패 시 **커밋·PR·CI가 막힘**.

```
당신은 Cursor 에이전트 하네스 구축 에이전트입니다.
빈 폴더에 **3세대 운영 하네스**를 만드세요.
(앱이 아니라 Cursor에게 누가·무엇을·어떤 순서로·어떤 검증 후 일할지
알려 주고 스크립트·CI로 강제하는 운영 프레임워크입니다.)

## 세대 정의 — 다섯 레이어
| 레이어 | 만드는 것 |
|--------|----------|
| Ambient | AGENTS.md, docs/harness/playbook.md, introduction.md |
| Rules | .cursor/rules/*.mdc (orchestrator + 역할별) |
| Skills | .cursor/skills/* (절차) |
| Runtime | scripts/, githooks, CI |
| MCP | mcp.json.example, mcp-setup.md (선택) |

## 필수 산출물

### Ambient
- AGENTS.md — 프로젝트명, 스택, 역할·경로, Daily/PR 검증 명령
- docs/harness/introduction.md — 입구 (3세대 레이어 표는 여기만)
- docs/harness/playbook.md — 역할, 워크플로, 디스패치, 실패 시 조치
- docs/harness/todo.md, TEMPLATE.md, first-ticket.md, glossary.md
- docs/harness/evolution.md — 1·2·3세대 정의 (4세대는 범위 밖)

### Rules (6개)
orchestrator.mdc (alwaysApply, 짧게) + editor, contract, backend, frontend, qa
→ globs는 [내 프로젝트] 폴더에 맞게

### Skills (최소 3개, 권장 6개)
필수: harness-gate, pr-workflow, worktree-setup
권장: dispatch, contract-handoff, backend-test-gate

### Runtime — scripts/ (Windows .ps1 + Mac/Linux .sh 쌍)
- validate-harness (일반 + -Pr: 브랜치·todo·커밋 검사)
- run-eval (프로젝트 테스트; 없으면 smoke/PASS 폴백)
- install-githooks
권장: dispatch-prompt, verify-dispatch, validate-handoff, summarize-eval

### CI · hooks
- .github/workflows/harness-gate.yml — jobs: validate, test
- .github/PULL_REQUEST_TEMPLATE.md
- pre-commit → validate-harness

### 계약·연습 (권장)
- handoff-schema.md + examples/
- sample/ mock (선택)
- eval/harness-smoke (선택)

## 워크플로 (playbook에 고정)
todo → feature/티켓번호-이름 브랜치 → Contract(handoff) → Backend/Frontend(병렬 가능)
→ QA → PR → CI → no-ff merge
main 직접 커밋·push 금지

## 검증 (구축 완료 후)
pwsh scripts/validate-harness.ps1
pwsh scripts/install-githooks.ps1
pwsh scripts/run-eval.ps1
# 기능 브랜치에서
pwsh scripts/validate-harness.ps1 -Pr

## 토큰 효율 (orchestrator·playbook)
- 질문만: 파일 읽기·디스패치 생략
- 구현: todo + 변경 파일만
- playbook 전체 로드 금지

## 만들지 말 것 (4세대 — 범위 밖)
- 서브에이전트 API 오케스트레이터 플랫폼
- PR마다 실제 LLM 자동 회귀 CI
- 비용·토큰 관측 대시보드 서비스

## 완료 기준
- [ ] validate-harness PASS
- [ ] 기능 브랜치에서 validate-harness -Pr PASS
- [ ] run-eval PASS
- [ ] first-ticket.md로 첫 기능 연습 경로 문서화
- [ ] introduction.md에 3세대 레이어 표 (개념 상세는 여기만)
- [ ] evolution.md에 3세대 목표 명시
- [ ] 루트 README에 학습 순서 표

[내 프로젝트]
- 이름:
- 스택:
- 폴더:
- 원하는 세대: 3
```

---

## 세대 업그레이드 (이미 하네스가 있을 때)

빈 폴더가 아니라 **기존 하네스를 올릴 때**.

```
현재 하네스를 다음 세대로 업그레이드하세요.

## 현재 세대: [1 | 2]
## 목표 세대: [2 | 3]

## 규칙
- 기존 파일 백업 후 병합 (덮어쓰기 전 diff)
- 추가되는 레이어만 최소 diff
- 3세대로 올리면 업그레이드 후 validate-harness PASS 필수

## 1 → 2 추가
.cursor/rules/ 역할별 mdc, AGENTS.md, playbook.md, todo.md, glossary.md, PR 템플릿

## 2 → 3 추가
scripts/validate-harness, run-eval, install-githooks (ps1+sh),
.cursor/skills/ (harness-gate, pr-workflow, worktree-setup 이상),
CI harness-gate, introduction.md, first-ticket.md, TEMPLATE.md
권장: dispatch, contract-handoff, handoff-schema, validate-handoff

## 완료 후
- README에 현재 세대(1|2|3) 명시
- 3세대면 validate-harness PASS

[내 프로젝트]
- 이름:
- 스택:
- 폴더:
- 현재 세대:
- 목표 세대:
```

---

## 관련 문서

| 문서 | 용도 |
|------|------|
| [evolution.md](./evolution.md) | 세대 정의 |
| [how-to-use.md](./how-to-use.md) | 경로 A(템플릿) vs B(이 문서) |
| [TEMPLATE.md](./TEMPLATE.md) | clone/템플릿 채택 체크리스트 |
| [introduction.md](./introduction.md) | 3세대 레이어 표 |
