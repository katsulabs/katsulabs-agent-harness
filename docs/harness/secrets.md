# Secrets 가이드

배포·MCP·CI 전 토큰·비밀 관리 절차.

## 원칙

- **커밋 금지**: `.env`, `.cursor/mcp.json`, 실제 토큰
- **예시만 커밋**: `.env.example` (값은 플레이스홀더)
- **CI**: GitHub Actions secrets · OIDC 권장

## 로컬

```bash
cp .env.example .env
# .env는 .gitignore에 추가
```

| 변수 | 용도 |
|------|------|
| `GITHUB_TOKEN` | MCP GitHub · gh CLI |
| `MCP_*` | MCP 서버별 (문서화) |

## Cursor MCP

`.cursor/mcp.json` — `mcp-setup.md` 참고. env는 OS 환경변수 또는 `.env`(비커밋)에서 주입.

## CI

- fork PR: secrets 미노출 workflow 유지
- `harness-gate`는 secrets 불필요 (validate + sample test)

## 체크리스트

- [ ] `.env` · `mcp.json` gitignore
- [ ] `.env.example` 최신 유지
- [ ] 회전 일정 캘린더 등록 · 상세: `secrets-rotation.md`

배포 전 전체 정책은 본인 보안 기준에 따른다.
