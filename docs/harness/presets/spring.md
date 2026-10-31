# Spring / Maven 프리셋

## globs

| 규칙 | globs |
|------|-------|
| backend | `src/main/java/**`, `modules/**/src/**` |
| frontend | `frontend/**`, `client/**` |
| contract | `**/dto/**`, `contracts/**`, `db/**` |

## run-eval

```powershell
# pom.xml 있으면 자동: mvn test -q
```

## 핸드오프

migration + OpenAPI → `handoff-schema.md`
