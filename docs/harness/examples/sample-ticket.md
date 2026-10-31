# 샘플 티켓 TB-004

| 필드 | 값 |
|------|-----|
| ID | TB-004 |
| 담당 | Editor → QA |
| DoD | validate 통과, CI green, PR 머지 |

## Editor 단계

```
[TB-004][Editor] playbook KPI 섹션 추가
```

- 변경: `docs/harness/playbook.md` (KPI 섹션만)
- 검증: `validate-harness`

## QA 단계

```
[TB-004][QA] PR 생성 및 CI 확인
```

- `validate-harness -Pr`
- PR 본문: `examples/sample-pr.md` 참고
- CI harness-gate green 후 머지
