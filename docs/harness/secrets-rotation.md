# Secrets 회전

`secrets.md` 기본 정책의 **회전·폐기** 절차.

## 주기 (권장)

| 비밀 | 회전 | 담당 |
|------|------|------|
| `GITHUB_TOKEN` | 90일 | 플랫폼 |
| MCP API keys | 90일 | 통합 소유자 |
| CI deploy keys | 180일 | DevOps |

## 회전 절차

1. 새 시크릿 발급 (기존 유지)
2. CI·로컬·MCP에 새 값 배포
3. smoke test (MCP 연결·CI green)
4. 구 시크릿 폐기·감사 로그
5. `.env.example`·문서 갱신

## 긴급 폐기

유출 의심 시: 즉시 폐기 → CI secrets 교체 → `todo.md`에 사후 티켓

## 체크리스트

- [ ] 회전 일정 캘린더 등록
- [ ] fork PR secrets 노출 정책 확인
- [ ] OIDC 전환 검토 (장기)

Vault·KMS 연동은 배포 환경에 맞게 별도 설계.
