@AGENTS.md

## Claude Code

- 계약·검증·금지는 위 `AGENTS.md`가 단일 진실. 여기엔 Claude 전용 사항만.
- 훅(`.claude/settings.json`)이 `scripts/guard-tool.sh`(main 커밋/푸시 차단 · 역할 범위)와 `scripts/stop-gate.sh`(종료 전 validate)를 실행한다. 설명: `docs/harness/modernization.md`
- 서브에이전트 디스패치 시 `HARNESS_ROLE=<Role>` 환경에서 실행하면 역할 범위 밖 편집이 차단된다.
- 스킬은 `.cursor/skills/`가 원본, `.claude/skills/`는 `scripts/sync-adapters.sh`로 생성 (직접 편집 금지).
