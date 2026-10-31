# How to use — 신규 프로젝트에서 하네스 쓰기

이 문서는 **신규 프로젝트를 시작할 때** 무엇을 하면 되는지 정리한다.  
Bootstrap 프롬프트와 이 starter clone은 **서로 다른 경로**다.

입구: 루트 [README.md](../../README.md) · 개념: [introduction.md](./introduction.md) · 채택: [TEMPLATE.md](./TEMPLATE.md)  
**빈 폴더용 세대별 프롬프트:** [bootstrap-prompts.md](./bootstrap-prompts.md)

---

## 한눈에: 경로 A vs B

| | **A. 이 starter를 템플릿으로** | **B. 빈 폴더 + Bootstrap 프롬프트** |
|--|-------------------------------|-------------------------------------|
| 언제 | 이미 이 저장소가 있고, 그걸 기반으로 새 앱을 만들 때 | 하네스 파일을 처음부터 생성하고 싶을 때 |
| 시작점 | GitHub “Use this template” 또는 `clone` | 빈 디렉터리 |
| 하는 일 | `AGENTS`·globs·`run-eval` 맞추기 | [bootstrap-prompts.md](./bootstrap-prompts.md)를 Cursor에 붙여 생성 |
| Bootstrap 프롬프트 | **쓰지 않음** (이미 하네스가 있음) | **씀** — 저장소 문서가 정본 |
| 결과 | 이 하네스 구조가 들어 있는 새 프로젝트 | 에이전트가 세대(1·2·3)에 맞게 하네스를 새로 만듦 |

**보통은 A.** 이 저장소를 clone/template 했다면 Bootstrap을 다시 돌릴 필요 없다.

**Notion?** — 필수가 아니다. 예전에 Notion에 정리해 둔 Bootstrap은 **미러/개인 메모**일 수 있다. 경로 B의 정본은 이 저장소의 [bootstrap-prompts.md](./bootstrap-prompts.md)다.

---

## 경로 A — 템플릿 채택 (권장)

### 1. 저장소 만들기

```bash
# GitHub: Use this template → 새 저장소 생성
# 또는
git clone <이-starter-URL> my-app
cd my-app
```

원격은 **내 프로젝트 저장소**로 바꾼다.

```bash
git remote rename origin upstream   # 선택: starter를 upstream으로 남김
git remote add origin <내-프로젝트-remote>
```

### 2. 프로젝트에 맞추기

1. `AGENTS.md` `[대괄호]` 채우기 (이름·스택·구조)
2. `.cursor/rules/*.mdc` globs를 실제 폴더에 맞게 수정 (`server/`, `client/` 등)
3. `docs/harness/playbook.md` 역할 표와 globs 동기화
4. `scripts/run-eval.ps1` / `run-eval.sh`에 프로젝트 테스트 명령 연결
5. (선택) `docs/harness/presets/`에서 스택 프리셋 참고

상세 체크리스트: [TEMPLATE.md](./TEMPLATE.md)

### 3. 게이트 설치·검증

```powershell
pwsh scripts/validate-harness.ps1
pwsh scripts/install-githooks.ps1
pwsh scripts/run-eval.ps1
```

### 4. 첫 커밋·push

- `main`에 바로 올리지 말고 `feature/TB-001-harness-adopt` 등에서 맞춘 뒤 PR (또는 첫 push 정책에 맞게)
- GitHub: CI `validate` + `test`, branch protection 권장 — [operations.md](./operations.md)

### 5. 첫 기능

[first-ticket.md](./first-ticket.md)로 30분 연습 후, 일상은 [playbook.md](./playbook.md) · `dispatch-prompt`.

---

## 경로 B — 빈 폴더 + Bootstrap

이 starter를 **쓰지 않고**, 빈 폴더에서 하네스만 만들고 싶을 때.

1. [bootstrap-prompts.md](./bootstrap-prompts.md)에서 **세대(1·2·3)** 선택 — 보통 **3**
2. 해당 프롬프트 **전체** 복사
3. 맨 아래만 채우기:

```text
[내 프로젝트]
- 이름: 쇼핑몰 API
- 스택: Node + React
- 폴더: server/, client/
- 원하는 세대: 3
```

4. **빈 폴더**를 Cursor로 연 뒤 붙여넣기
5. 에이전트가 파일·스크립트를 생성하면 `validate-harness` 등 안내에 따라 검증
6. `git init` → 새 remote 연결 → push

내부 티켓 번호는 적지 않는다. 사용자는 프로젝트 4줄 + 세대만 채운다.  
세대 정의: [evolution.md](./evolution.md)

---

## 하지 말 것

| 잘못된 이해 | 올바른 이해 |
|-------------|-------------|
| clone 후 Bootstrap 프롬프트를 또 붙여넣기 | clone이면 **경로 A** — 맞추기만 |
| Bootstrap에 `TB-011`, `validate-harness -Pr`를 사용자가 적기 | 그건 프롬프트 **본문(에이전트용)** · 사용자는 `[내 프로젝트]`만 |
| 맞추기 전에 바로 `main`에 앱 코드 push | 먼저 하네스 채택·검증, 기능은 feature 브랜치 |

---

## 채택 후 일상 (A·B 공통)

```text
todo 등록 → feature/TB-{id}-* 브랜치 → Contract → BE/FE → QA → PR → CI → no-ff merge
```

| 상황 | 명령 / 문서 |
|------|-------------|
| 역할별 프롬프트 | `pwsh scripts/dispatch-prompt.ps1 -Ticket TB-xxx -Role Backend` |
| Daily 검증 | `validate-harness` · `run-eval` |
| PR 직전 | `validate-harness -Pr` · `summarize-eval` · 스킬 `pr-workflow` |

---

## 관련 문서

| 문서 | 용도 |
|------|------|
| [TEMPLATE.md](./TEMPLATE.md) | 채택 체크리스트 (신규·기존 저장소) |
| [first-ticket.md](./first-ticket.md) | 첫 티켓 30분 |
| [getting-started.md](./getting-started.md) | 읽기 순서 허브 |
| [bootstrap-prompts.md](./bootstrap-prompts.md) | 빈 폴더 — 1·2·3세대 생성 프롬프트 (경로 B 정본) |
| [evolution.md](./evolution.md) | 1·2·3세대 정의 |
