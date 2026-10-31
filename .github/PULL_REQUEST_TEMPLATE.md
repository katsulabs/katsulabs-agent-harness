## 요약

<!-- 무엇을 왜 -->

## 검증 계획

- [ ] `validate-harness -Pr` 통과 (`pwsh scripts/validate-harness.ps1 -Pr` 또는 `./scripts/validate-harness.sh -Pr`)
- [ ] `run-eval` 통과 (앱 테스트 또는 `harness-smoke`)
- [ ] `eval/reports/latest-harness-smoke.json` · `latest-agent-eval.json` status 확인
- [ ] CI `validate` + `test` green
- [ ] `main` 직접 커밋 없음

## 테스트 게이트

- [ ] Backend test passed (N/A 가능)
- [ ] Frontend test passed (N/A 가능)
- [ ] Contract/API 변경 시 핸드오프 메모 첨부 · `validate-handoff` PASS (N/A 가능)
- [ ] Agent smoke: `run-agent-eval` PASS 또는 checklist 수동 기록 (N/A 가능)

## 하드 게이트

- [ ] 티켓 ID·범위 명시
- [ ] 브랜치 규칙 준수
- [ ] DB/migration 변경 시 호환성·rollback 메모 (N/A 가능)
- [ ] Hook fallback 시 사유 기록 (N/A 가능)
