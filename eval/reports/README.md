# Eval Reports

`harness-smoke`·`run-agent-eval` 실행 시 JSON 리포트가 생성된다. PR 본문이나 CI 아티팩트에 첨부한다.

| 파일 | 생성 스크립트 |
|------|----------------|
| `latest-harness-smoke.json` | `eval/harness-smoke` |
| `latest-agent-eval.json` | `scripts/run-agent-eval` |

타임스탬프 파일(`*-YYYY-MM-DD*.json`)은 로컬·CI 캐시용. **커밋하지 않는다** (`.gitignore`).
