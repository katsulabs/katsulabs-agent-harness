# 하네스 템플릿 적용 가이드

`katsulabs-agent-harness`를 개발 프로젝트에 붙이는 절차.

**경로 선택(템플릿 vs 빈 폴더 Bootstrap):** [how-to-use.md](./how-to-use.md) — 이 문서는 **경로 A(템플릿 채택)** 체크리스트다.

## 신규 저장소

1. 이 템플릿 파일을 프로젝트 루트에 복사
2. `AGENTS.md` [대괄호] 항목을 프로젝트에 맞게 작성
3. `.cursor/rules/*.mdc` globs를 실제 디렉터리에 맞게 수정
4. `playbook.md` 역할 테이블 동기화
5. hooks 설치 (`install-githooks.ps1` 또는 `.sh`) — `setup-shell.md` 참고
6. `docs/harness/todo.md`에 첫 티켓/DoD 입력
7. GitHub: `harness-gate` CI + branch protection (`validate` check)

## 기존 저장소

1. **충돌 확인**: 기존 `.cursor/rules`, `AGENTS.md`, `.github/workflows` 백업
2. 템플릿 파일을 **병합** (덮어쓰기 전 diff 검토)
3. globs·경로를 기존 구조에 맞게 조정 (`.cursor/rules/backend.mdc` 등)
4. `scripts/run-eval.ps1` / `run-eval.sh`에 프로젝트 테스트 명령 연결
5. PR 템플릿 테스트 항목을 스택에 맞게 수정
6. `validate-harness` 통과 후 첫 harness PR 생성

## worktree (병렬 티켓)

```bash
git worktree add ../.worktrees/TB-123-feature -b feature/TB-123-feature
# 작업 후
git worktree remove ../.worktrees/TB-123-feature
```

`.worktrees/`는 `.gitignore`에 추가 권장.

레이어 개요: [introduction.md](./introduction.md)

## 체크리스트

- [ ] AGENTS.md 채움
- [ ] globs ↔ 실제 경로 일치
- [ ] `validate-harness` PASS (`.ps1` 또는 `.sh`)
- [ ] `run-eval` 연결 또는 harness-smoke PASS 확인
- [ ] 핸드오프: `handoff-schema.md` 경로 정하기
- [ ] 스택 프리셋: `presets/node.md` 등
- [ ] `first-ticket.md`로 첫 티켓 시뮬레이션
- [ ] MCP 필요 시 `mcp.json.example` 참고해 설정
