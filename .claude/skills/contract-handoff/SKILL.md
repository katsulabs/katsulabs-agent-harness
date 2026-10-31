---
name: contract-handoff
description: Write and validate a Contract handoff (API, DTO, DB, TODOs per side) before dispatching Backend and Frontend agents. Use after the API/DTO is fixed. API/DTO 고정 후 핸드오프 작성·검증.
disable-model-invocation: true
---

# Contract Handoff

Requires: `bash`. `git` is optional (used only to find the repo root).

## Steps

1. Create the skeleton

   ```bash
   bash <skill-dir>/scripts/new-handoff.sh TB-101            # Korean headings
   bash <skill-dir>/scripts/new-handoff.sh TB-101 --lang en  # English headings
   # → docs/handoffs/TB-101-handoff.md  (docs/harness/handoffs/ if that directory exists)
   ```

2. Fill in the sections ([references/handoff-schema.md](references/handoff-schema.md) has the format and a full example).
3. Set `status: ready` once the contract is final.
4. Validate

   ```bash
   bash <skill-dir>/scripts/validate-handoff.sh                 # all handoffs in the dir
   bash <skill-dir>/scripts/validate-handoff.sh path/to/file.md # one file
   ```

   ```text
   PASS: validate-handoff (1 file(s))
   FAIL: validate-handoff (1 issue(s))
     - SECTION: docs/handoffs/TB-101-handoff.md — '## DTO' (or '## DTO') missing
   ```

5. If `breaking: true`, tell QA and Frontend explicitly.
6. Dispatch Backend/Frontend (the `dispatch` skill, if you use it).

## What is checked

Frontmatter keys `ticket, from, to, status, breaking`; `status` is `ready|blocked`; `breaking` is `true|false`; all six sections present (KO or EN headings).

## Options (env)

`HANDOFF_DIR` overrides the handoff directory.

한국어: API/DTO 확정 후, Backend/Frontend 디스패치 전에 작성·검증. 섹션 제목은 한국어/영어 모두 허용.
