# Eval 가이드

**언제 무엇을 실행할지** 한 곳에서 정리. 상세 절차는 링크 참고.

## 결정 트리

```text
티켓 작업 중?
  └─ 코드/핸드오프 변경 후 → run-eval
       (앱 테스트 · sample test · harness-smoke)

PR 만들기 직전?
  └─ validate-harness -Pr
       (+ verify-dispatch · todo-sync · commit-msg)

PR 본문 작성?
  └─ summarize-eval -OutFile eval/reports/pr-eval-summary.md

Contract 핸드오프 작성·수정?
  └─ validate-handoff

릴리스 전 · 규칙 대폭 변경?
  └─ run-agent-llm-eval → (수동 세션) → score-agent-llm / -Validate
```

## 종류별 요약

| 이름 | 자동? | 무엇을 검사 |
|------|-------|-------------|
| `run-eval` | CI·로컬 | **앱 테스트** + `harness-smoke` |
| `harness-smoke` | `run-eval` 내부 | 하네스 파일·규약·handoff·fixture |
| `run-agent-eval` | harness-smoke 내부 | rules·skills **정적** 프록시 (AS-01~04) |
| `score-agent-llm -Fixture` | CI | 응답 **패턴** fixture (LLM 호출 없음) |
| `run-agent-llm-eval` | 수동(권장) | LLM **행동** 회귀 세션 |
| `run-llm-ci` | 수동·주간 CI | 헤드리스 LLM 회귀 + 토큰/비용 (`--dry-run`은 smoke 포함) |

## 수동 체크리스트

- 정적 회귀: `eval/agent-smoke.checklist.md`
- LLM 행동: `eval/agent-tasks/harness-baseline.md` · `agent-llm-eval.md`

## 리포트

`eval/reports/latest-*.json` · PR용: `summarize-eval` · `eval/reports/README.md`
