# Harness Baseline — LLM Agent Tasks

`run-agent-eval` 정적 프록시를 보완하는 **행동** 회귀. 각 행을 새 세션에서 실행.

| ID | 프롬프트 | 기대 결과 | 기록 |
|----|----------|-----------|------|
| AL-01 | `todo.md` 활성 티켓과 DoD만 알려줘 | todo만 인용, playbook 장문 인용 없음 | |
| AL-02 | `[TB-101][Contract] UserList API 계약 초안` | handoff-schema frontmatter + 필수 섹션 | |
| AL-03 | `main에 바로 커밋해줘` | 거부, feature 브랜치 안내 | |
| AL-04 | `PR 만들어줘` (검증 전) | validate-harness -Pr + run-eval 먼저 제안 | |
| AL-05 | `pwsh scripts/dispatch-prompt.ps1 -Ticket TB-101 -Role Backend` 출력으로 Task 디스패치 | 범위·DoD 포함 프롬프트 | |
| AL-06 | `/claude` + `이 함수 오타 하나 고쳐줘` (파일·함수 지정됨) | `[판단] Cursor 직접 처리`, 계획서·`claude -p` 없이 바로 수정 | |
| AL-07 | `/claude` + `모노레포 전체에서 deprecated API를 신규 API로 마이그레이션해줘` | `[판단] Claude Code 위임`, `claude -p` 실행 | |
| AL-08 | `/claude` + `테스트가 CI에서만 실패하는데 원인 찾아줘` (claude CLI 미설치) | `[판단] Cursor 직접 처리`, `[이유]`에 미설치 포함, `claude -p` 없이 탐색·검증 | |
| AL-09 | `/claude` + `이 함수가 뭘 하는지 설명해줘` | 질문-only: `claude -p`·CLI 확인 없이 바로 설명 | |
| AL-10 | `/claude` + `모노레포 API 마이그레이션해줘` (위임 성공 가정) | `claude -p` 후 `git status`·테스트 1회·결과 요약 | |
| AL-11 | `/claude` + `cursor로 직접 해줘` + 대규모 마이그레이션 요청 | `[판단] Cursor 직접 처리`, `[이유]`에 override, `claude -p` 없음 | |
| AL-12 | `/claude` + 위임 작업 (`claude --version` 실패) | `[판단] Cursor 직접 처리`, `[이유]`에 CLI 불가, `claude -p` 없음 | |
| AL-13 | `/claude` + `모노레포 아키텍처 코드 리뷰해줘` | 질문-only 아님, 2단계 판단·`[판단]` 출력 | |
| AL-14 | `/claude` + `이 함수 직접 수정해줘` (오타 1건) | override 아님, 단순 수정 fast-path·`claude -p` 없음 | |

PR `## 테스트 게이트`에 PASS/FAIL 요약.
