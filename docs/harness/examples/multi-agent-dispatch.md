# Multi-agent 디스패치 예시 (TB-101)

이 하네스에서 **자연어 → 메인 오케스트레이터 → Task 서브에이전트**로 일할 때 쓰는 명령 예시.  
규약: [playbook.md](../playbook.md) 서브에이전트 섹션 · 스킬 `dispatch` · `scripts/dispatch-prompt.ps1`

샘플 티켓 개요: [sample-ticket-code.md](./sample-ticket-code.md)

---

## 흐름

```text
메인(자연어)
  → Task[Contract]
  → Task[Backend] ║ Task[Frontend]   (병렬)
  → Task[QA]
  → 메인에 산출물·검증 보고
```

| 단계 | 누가 | 명령 성격 |
|------|------|-----------|
| 착수 | 메인 | 자연어 + todo/브랜치 |
| 역할 작업 | Task 서브에이전트 | `[TB-101][Role]` 프롬프트 |
| 프롬프트 생성 | 사람/메인 | `dispatch-prompt.ps1` |
| PR 전 | QA / 메인 | `verify-dispatch` · `validate-harness -Pr` |

---

## 1. 메인에 넣는 자연어

```
TB-101 사용자 목록 API + UI를 multi-agent로 진행해줘.

1. docs/harness/todo.md에 TB-101 등록 (DoD: Contract 고정 → BE/FE → run-eval → PR)
2. feature/TB-101-user-list 브랜치(또는 worktree) 준비
3. 서브에이전트(Task)로 순서대로 디스패치:
   - Contract → Backend + Frontend(병렬) → QA
4. 각 역할은 dispatch-prompt 출력(또는 동등 프롬프트) 사용
5. 역할 끝나면 산출물 경로·검증 결과를 메인에 보고
6. QA에서 validate-harness -Pr + run-eval 후 PR까지
```

짧게:

```
[TB-101] 사용자 목록 API+UI — Contract → BE/FE 병렬 → QA 로 Task 디스패치해서 끝까지 진행해.
todo 등록·feature/TB-101-user-list 브랜치 필수. main 커밋 금지.
```

---

## 2. 역할별 프롬프트 생성

```powershell
pwsh scripts/dispatch-prompt.ps1 -Ticket TB-101 -Role Contract
pwsh scripts/dispatch-prompt.ps1 -Ticket TB-101 -Role Backend
pwsh scripts/dispatch-prompt.ps1 -Ticket TB-101 -Role Frontend
pwsh scripts/dispatch-prompt.ps1 -Ticket TB-101 -Role QA
```

```bash
./scripts/dispatch-prompt.sh TB-101 Contract
./scripts/dispatch-prompt.sh TB-101 Backend
./scripts/dispatch-prompt.sh TB-101 Frontend
./scripts/dispatch-prompt.sh TB-101 QA
```

출력을 Cursor **Task** 서브에이전트에 붙여넣고, 아래처럼 한 줄만 구체화해도 된다.

---

## 3. Contract (먼저)

```
[TB-101][Contract] UserList API 계약 고정

## 범위
db/**, **/dto/**, contracts/**, api-spec/**

## 지시
- GET /api/users 계약만. 구현 코드 금지.
- handoff-schema.md 형식으로 docs/harness/handoffs/TB-101-handoff.md 작성
- pwsh scripts/validate-handoff.ps1 PASS

## DoD
- 엔드포인트·응답 스키마·에러코드 명확
- Backend/Frontend가 이 핸드오프만 보고 구현 가능
```

---

## 4. Backend (Contract 후 · Frontend와 병렬 가능)

```
[TB-101][Backend] GET /api/users 구현

## 범위
modules/**, backend/**, server/**, api/**

## 지시
1. docs/harness/handoffs/TB-101-handoff.md 확인 후 구현
2. 계약 불일치 시 Contract에 역보고 — 임의 변경 금지
3. sample/server 참고 가능. UI·문서 범위 침범 금지
4. pwsh scripts/run-eval.ps1 PASS

## DoD
- todo TB-101 DoD 중 서버 부분 충족
- 핸드오프와 구현 일치
```

---

## 5. Frontend (Contract 후 · Backend와 병렬)

```
[TB-101][Frontend] 사용자 목록 페이지

## 범위
frontend/**, client/**, apps/web/**

## 지시
1. TB-101-handoff.md 기준 API 타입·에러 동기화
2. UI만. 서버·계약 파일 변경 금지
3. sample/client 참고 가능
4. pwsh scripts/run-eval.ps1 PASS

## DoD
- 목록 UI + API 연동
- 핸드오프와 타입 일치
```

---

## 6. QA (마지막)

```
[TB-101][QA] 기능 검수 및 PR

## 범위
validate-harness, run-eval, CI

## 지시
1. diff·핸드오프·todo DoD 대조
2. pwsh scripts/validate-harness.ps1 -Pr
3. pwsh scripts/run-eval.ps1
4. summarize-eval → PR ## 검증 계획
5. gh pr create · CI green → no-ff merge

## DoD
- -Pr PASS · run-eval PASS · PR 본문에 TB-101·검증 결과
```

---

## 하지 말 것

- 메인에 “알아서 multi-agent로 해”만 쓰고 티켓·DoD·브랜치를 안 적기
- Contract 없이 BE/FE 동시 착수
- `main`에서 Task 돌리기 (`feature/TB-101-*` 필요)

---

## 관련

| 문서·도구 | 용도 |
|-----------|------|
| [multi-agent-walkthrough.md](./multi-agent-walkthrough.md) | dispatch-plan→collect-handoff 실행 walkthrough |
| [sample-ticket-code.md](./sample-ticket-code.md) | TB-101 단계 요약 |
| [contract-handoff.md](./contract-handoff.md) | 핸드오프 예시 |
| `.cursor/skills/dispatch/SKILL.md` | 디스패치 절차 |
| `pwsh scripts/verify-dispatch.ps1` | PR 전 브랜치 규약 |
