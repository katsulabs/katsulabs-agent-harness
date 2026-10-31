# MCP 설정 가이드

MCP는 Skills(절차)를 보완하는 **live API** 연동층이다. 선택 사항.

## 1. 파일 준비

```bash
cp .cursor/mcp.json.example .cursor/mcp.json
```

`.cursor/mcp.json`은 **커밋하지 않는다** (토큰 포함). `.gitignore`에 추가 권장.

## 2. 서버 예시

| 용도 | 서버 | env |
|------|------|-----|
| 이슈·PR | `@modelcontextprotocol/server-github` | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| DB 조회 | 자체 MCP 또는 Snowflake/Postgres 플러그인 | 비밀관리 |
| API 테스트 | Postman MCP (Cursor 플러그인) | Postman API key |

## 3. AGENTS.md 기록

채택한 MCP를 AGENTS.md `## MCP` 절에 나열:

```markdown
## MCP (사용 중)
- github: 이슈·PR 조회
- postman: API 컬렉션 실행
```

## 4. Skills와 역할 분담

| | Skill | MCP |
|---|-------|-----|
| 시점 | PR·worktree 등 절차 | 런타임 데이터 조회·변경 |
| 예 | `pr-workflow` | `gh pr checks` 대신 GitHub MCP |

## 5. 검증

- Cursor Settings → MCP에서 서버 green 확인
- 티켓 착수 시 `todo.md` ID와 외부 이슈 키 매핑 문서화 (선택)

## 6. 보안

- 토큰은 OS 비밀관리·CI secrets만 사용
- `Secrets management`는 배포 전 별도 티켓 (todo 보류 항목)
