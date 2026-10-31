# 운영 메모

## 설정 체크리스트

| 항목 | 상태 |
|------|------|
| CI harness-gate | `validate` + `test` |
| branch protection | `validate` (+ `test` 권장) |

## branch protection (`main`)

권장 status checks: **`validate`**, **`test`** (strict)

```json
{
  "required_status_checks": { "strict": true, "contexts": ["validate", "test"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null
}
```

```bash
gh api -X PUT repos/OWNER/REPO/branches/main/protection --input protection.json
```

## CI 확인

```bash
gh run list --workflow harness-gate
gh pr checks
```
