# Agent LLM Eval (수동)

**개요·결정 트리:** [eval-guide.md](./eval-guide.md)

## 절차 (LLM 행동 회귀)

1. `run-agent-llm-eval` — 세션 템플릿
2. [harness-baseline.md](../../eval/agent-tasks/harness-baseline.md) 태스크 실행
3. `agent-llm-session.md`에 PASS/FAIL · 응답 요약
4. `score-agent-llm -Session` 또는 `run-agent-llm-eval -Validate -AutoScore`
5. `summarize-eval` → PR

릴리스 전·규칙 대变更 후 권장.
