# Agent Harness 세대 (진화 모델)

**이 저장소가 말하는 “3세대”**는 Cursor 제품 버전이 아니라, **에이전트 운영 방식의 성숙도**를 구분하는 내부 프레임입니다. TB-009에서 정리했고, 이 문서가 **1·2·3세대 정의와 변화**를 한곳에 둡니다.

레이어 표·다이어그램: [introduction.md](./introduction.md) — 여기서는 **왜 3세대인지**만 설명합니다.

---

## 한눈에


| 세대       | 한 줄                                              | 강제력                  |
| -------- | ------------------------------------------------ | -------------------- |
| **1세대**  | 긴 프롬프트·단일 rules 파일                               | 없음 (말로만)             |
| **2세대**  | Rules + 문서 (역할·규약)                               | 없음 (권고)              |
| **3세대**  | Ambient + Rules + **Skills** + **Runtime** + MCP | **스크립트·CI·hooks**    |
| **4세대+** | 플랫폼 (오케스트레이션·관측·상태)                              | 런타임이 에이전트를 **대신 실행** |


이 템플릿은 **3세대 천장**을 목표로 합니다. 4세대는 의도적으로 범위 밖이지만, 도구 중립·에이전트 훅·실제 LLM eval/비용 같은 최근 트렌드는 3세대 안에서 흡수합니다 → [modernization.md](./modernization.md).

---

## 1세대 — 프롬프트 엔지니어링

**특징**

- `.cursorrules` 한 파일, 또는 채팅마다 붙이는 긴 시스템 프롬프트
- “main에 커밋하지 마”, “테스트 돌려” 같은 규칙이 **텍스트로만** 존재
- 역할(Contract/Backend 등) 구분 없음

**한계**

- 세션·모델·사람마다 규칙 준수가 달라짐
- PR·브랜치·handoff 형식을 **검증할 수 없음**
- 문서가 길어질수록 토큰만 늘고 실제 행동은 안 바뀜

**이 하네스와의 관계:** 이미 넘어선 단계. `introduction.md`의 “README만 있을 때”가 1세대에 가깝습니다.

---



## 2세대 — 구조화된 규약

**특징**

- `.cursor/rules/*.mdc` — 역할·경로별 **조건부** 규칙
- `AGENTS.md`, `playbook.md`, README로 **운영 계약** 문서화
- 문서에 규약을 적어 두지만, **실행은 사람·에이전트 재량**

**한계**

- “validate 돌렸어요?”를 시스템이 막지 못함
- 멀티 역할·handoff·eval이 **문장으로만** 정의됨
- CI는 앱 테스트만 있고 **하네스 자체 건강**은 안 봄

**이 하네스와의 관계:** TB-001~003 구간(한글화·토큰 절감·`validate-harness` 도입 전후)이 2세대에서 3세대로 넘어가는 과도기였습니다.

---



## 3세대 — 운영 하네스 (이 템플릿)

**특징 — 다섯 레이어**


| 레이어     | 역할                   | 이 repo                             |
| ------- | -------------------- | ---------------------------------- |
| Ambient | 짧은 계약, 매 턴 상주        | `AGENTS.md`, `playbook.md`         |
| Rules   | 역할·globs             | `.cursor/rules/*.mdc`              |
| Skills  | PR·dispatch 등 **절차** | `.cursor/skills/`*                 |
| Runtime | **강제** 검증            | `scripts/`, githooks, CI           |
| MCP     | live API (선택)        | `mcp-setup.md`, `mcp.json.example` |


**3세대의 핵심 차이**

- 규칙이 **실패하면 커밋·PR·CI가 막힘** (`validate-harness`, `run-eval`, `-Pr` 게이트)
- Contract → BE/FE **handoff 스키마** + `validate-handoff`
- 에이전트 행동 **정적 회귀** (`run-agent-eval`, `harness-smoke`) — LLM 세션은 선택

**이 저장소에서의 마일스톤**


| 티켓         | 세대 관점에서 한 일                                   |
| ---------- | --------------------------------------------- |
| TB-009     | “3세대” 명명 · AGENTS·TEMPLATE·Skills·eval/MCP 골격 |
| TB-010     | Runtime 크로스플랫폼 (ps1/sh, CI matrix)            |
| TB-011~012 | harness-smoke, handoff 린터, agent-eval         |
| TB-013~015 | sample, dispatch, LLM eval 스켈레톤, PR 게이트 보강    |
| TB-016~017 | 역할 스킬·presets·문서 입구 정리                        |


---



## 4세대+ — 에이전트 플랫폼 (범위 밖)

**특징 (업계에서 말하는 다음 단계)**

- 오케스트레이터가 **서브에이전트를 API로 호출**하고 상태·메모리 유지
- PR마다 **실제 LLM** 회귀·토큰·비용 대시보드
- 이슈 트래커·배포와 **완전 자동** 파이프라인

**이 템플릿이 하지 않는 이유**

- Cursor IDE·Task 도구에 **실행 런타임을 묶지 않음** (템플릿은 repo 규약)
- LLM eval은 **수동 세션 + fixture 자동**까지 — API 호출 CI는 별도 인프라 영역
- `cost-summary` 등은 **추정·리포트**이지 관측 플랫폼이 아님

플랫폼이 필요하면 이 하네스 **위에** 별도 서비스를 올리는 구성을 권장합니다.

---



## 관련 문서


| 문서 | 내용 |
|------|------|
| [introduction.md](./introduction.md) | 3세대 레이어 표·다이어그램 |
| [bootstrap-prompts.md](./bootstrap-prompts.md) | 빈 폴더에서 1·2·3세대 생성 프롬프트 |
| [how-to-use.md](./how-to-use.md) | 템플릿 채택 vs Bootstrap |
| [glossary.md](./glossary.md) | TB, handoff 등 용어 |
| [todo.md](./todo.md) | 티켓별 구현 이력 |


