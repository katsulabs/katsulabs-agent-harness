# Sample TB-101

`sample-ticket-code.md`와 연결된 최소 BE/FE mock. 구조만 참고하고 실제 경로(`server/`, `client/`)로 복사한다.

| 경로 | 역할 |
|------|------|
| `api-spec/users.yaml` | Contract 산출물 |
| `server/users.js` | Backend 로직 |
| `client/user-list.html` | Frontend 스켈레톤 |

```bash
cd sample && npm test
```

루트에 앱 러너가 없으면 `run-eval`이 `sample/` 테스트를 실행한다.
