# 하네스 인수 테스트 (Acceptance Test)

하네스가 **문서·규칙·워크플로** 기준으로 올바르게 구성되었는지 검증하는 런북입니다.

예상 소요: **30~45분** (드릴 포함)

## 언제 실행하나

- 스타터를 새 프로젝트에 복사한 직후
- `customization.md`로 풀스택 확장을 마친 직후
- rules 또는 harness 문서를 크게 수정한 PR 머지 전

## 사전 조건

- Node.js 20+ (CI와 동일 권장)
- Git worktree 사용 가능
- Cursor에서 `.cursor/rules/*.mdc` 로드 가능

---

## 1. 자동 검증 (5분)

### 1-1. 로컬 문서 품질 게이트

```bash
./scripts/doc-quality-gate.sh
```

| 결과 | 판정 |
|------|------|
| `Document quality gate PASSED.` | PASS |
| exit code ≠ 0 | FAIL — 출력의 `FAIL:` 파일 링크 수정 |

### 1-2. CI (PR 또는 push 후)

PR을 열면 **Docs Quality Gate** 워크플로가 실행됩니다.

| 결과 | 판정 |
|------|------|
| GitHub Checks green | PASS |
| red | FAIL — Actions 로그에서 실패 파일 확인 |

로컬 PASS + CI PASS면 **문서 링크·구조**는 기본 OK입니다.

---

## 2. 정합성 검증 (10분)

rules(`.mdc`)와 docs(`docs/harness/**`)가 같은 모델을 가리키는지 확인합니다.

### 2-1. 풀스택 잔재 검색

`customization.md`는 풀스택 매핑 예시이므로 제외합니다.

```bash
rg 'Flyway|modules/\*\*|Vitest|backend test gate' docs .github \
  --glob '!customization.md'
```

| 결과 | 판정 |
|------|------|
| 매칭 0건 | PASS |
| 매칭 있음 | FAIL — doc-only 모델과 불일치 |

### 2-2. 역할 표 대조

[playbook.md](./playbook.md) 역할 표와 각 `.mdc`의 **수정 범위**가 일치하는지 확인합니다.

| Agent | `.mdc` 허용 경로 | 문서 관점 |
|-------|------------------|-----------|
| Contract | `docs/**`, `.cursor/rules/**`, `.github/**` | 요구사항·용어·계약 |
| Backend | `docs/**`, `.cursor/rules/**` | 시스템·운영 |
| Frontend | `docs/**`, `.github/**` | 사용자·협업 |
| QA | `docs/**`, `.cursor/rules/**`, `.github/**` | 품질 게이트·PR 검수 |

### 2-3. PR 템플릿

[`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md)에 아래가 **없어야** PASS:

- `backend test gate` / `frontend test gate`
- `DB/Flyway`

아래가 **있어야** PASS:

- `document quality gate`
- `role boundary` (Contract/Backend/Frontend/QA)

---

## 3. 운영 드릴 (20~30분)

가짜 티켓 **TB-999**로 end-to-end를 한 번 밟습니다.

### 3-1. 티켓 등록

`docs/harness/todo.md`에 추가 (드릴 후 삭제 또는 DONE 처리):

```markdown
| TB-999 | Main/Agent | TODO | acceptance-test.md §3 드릴 완료 |
```

DoD 예: `getting-started.md`에 acceptance-test 링크 1줄 추가 (이미 있으면 다른 § 참조 1줄)

### 3-2. Worktree

[playbook.md](./playbook.md) Worktree 섹션대로:

```bash
git fetch origin main
git worktree add ../katsulabs-TB-999-acceptance-drill \
  -b feature/TB-999-acceptance-drill origin/main
```

worktree 디렉터리에서 작업합니다.

| 결과 | 판정 |
|------|------|
| 브랜치 `feature/TB-999-acceptance-drill` 생성됨 | PASS |
| `main`에 직접 커밋하지 않음 | PASS |

### 3-3. Sub-agent 순차 분배

Cursor에서 아래 순서로 진행합니다. 각 턴 프롬프트 **첫 줄에 태그**를 넣습니다.

| 순서 | 태그 | 확인 사항 |
|------|------|-----------|
| 1 | `[TB-999][Contract]` | 범위·용어·DoD 고정; 구현 전 계약 |
| 2 | `[TB-999][Backend]` | `@backend.mdc`; `docs/**` 또는 rules만 수정 |
| 3 | `[TB-999][Frontend]` | `@frontend.mdc`; 사용자 관점 문구 |
| 4 | `[TB-999][QA]` | `@qa.mdc`; DoD·링크·PR 체크리스트 |

**PASS 조건:**

- [ ] 각 단계 diff가 [playbook.md](./playbook.md) 수정 범위 안
- [ ] Contract 산출물(범위 요약)이 다음 턴에 전달됨
- [ ] `./scripts/doc-quality-gate.sh` PASS

### 3-4. 수동 handoff 기록

Hook 없이 메인이 태그만 바꿔 넘겼다면 PR 본문에 기록:

```markdown
Manual handoff: Contract → Backend → Frontend → QA (TB-999 drill)
```

### 3-5. PR + 정리

1. PR 생성 → Docs Quality Gate green
2. 드릴 브랜치 머지 또는 폐기
3. worktree 제거:

```bash
git worktree remove ../katsulabs-TB-999-acceptance-drill
git branch -d feature/TB-999-acceptance-drill   # 머지 후
```

---

## 4. Cursor 규칙 스모크 (5분)

| # | 동작 | PASS |
|---|------|------|
| 1 | 새 Agent에 "TB-999 구현해줘" | `todo.md`·worktree·태그 분배를 먼저 언급 |
| 2 | `@backend.mdc`로 `.github/` 수정 요청 | 범위 밖임을 인지하거나 거절 |
| 3 | `@orchestrator.mdc` alwaysApply | main 직접 커밋 금지 등 전역 규칙 인지 |

---

## 5. 인수 체크리스트 (한 장)

복사해 PR 또는 팀 위키에 붙여넣습니다.

```markdown
## Harness acceptance — TB-xxx / YYYY-MM-DD

### 자동
- [ ] `./scripts/doc-quality-gate.sh` PASSED
- [ ] Docs Quality Gate CI PASSED

### 정합성
- [ ] playbook 역할표 ↔ .mdc 역할/경로 일치
- [ ] 풀스택 잔재 없음 (customization.md 제외)
- [ ] PR 템플릿 = document quality gate

### 운영
- [ ] TB-999 (또는 샘플) Contract→QA 드릴 완료
- [ ] 수동 handoff 1회 기록
- [ ] worktree 생성/제거 OK

### Cursor
- [ ] Orchestrator 첫 턴 체크리스트 동작
- [ ] Sub-agent globs 범위 준수

**판정:** PASS / FAIL
**비고:**
```

---

## 6. 이 런북이 잡지 못하는 것

| 항목 | 대안 |
|------|------|
| 문장 품질·명확성 | 사람/QA Agent 리뷰 |
| GitHub branch protection | repo 설정에서 `main` 보호 확인 |
| no-ff merge | merge 버튼 옵션·팀 규칙 |
| KPI 수치 | 1~2주 운영 후 별도 측정 |

---

## 관련 문서

- [eval-guide.md](./eval-guide.md) — 문서 품질 게이트 정의
- [getting-started.md](./getting-started.md) — 온보딩 체크리스트
- [playbook.md](./playbook.md) — worktree, Sub-agent, handoff
