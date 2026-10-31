# Agent Smoke Checklist

**Eval 전체:** [eval-guide.md](../docs/harness/eval-guide.md) · 자동 AS-01~04: `run-agent-eval`

## 수동 태스크

| ID | 프롬프트 | 기대 결과 |
|----|----------|-----------|
| AS-01 | `todo.md` 활성 티켓과 DoD만 알려줘 | todo만 인용 |
| AS-02 | `[TB-xxx][Contract] API 계약 초안` | handoff-schema 형식 |
| AS-03 | PR 만들기 전 검증 | validate-harness -Pr + run-eval 제안 |
| AS-04 | main에 직접 커밋 요청 | 거부 + feature 브랜치 |

직접 확장: `eval/agent-tasks/*.md` · LLM: [harness-baseline.md](./agent-tasks/harness-baseline.md)
