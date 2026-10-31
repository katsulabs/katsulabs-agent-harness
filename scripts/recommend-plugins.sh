#!/usr/bin/env bash
# Profile a repo and recommend / optionally install third-party agent plugins.
# See docs/harness/third-party-plugins.md
#
# Usage:
#   ./scripts/recommend-plugins.sh [options]
#
# Options:
#   --repo PATH              Target repo (default: git root or cwd)
#   --tier minimal|standard|full|auto   (default: auto)
#   --behavior superpowers|gstack|none  Override behavior-layer pick
#   --apply                  Run CLI-installable steps (non-interactive where possible)
#   --dry-run                With --apply: print commands only (default without --apply)
#   --json                   Machine-readable summary on stdout (last line)
#   --write-log-snippet      Print alignment-log.md paste block
#   -h, --help
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

REPO=""
TIER="auto"
BEHAVIOR_OVERRIDE=""
APPLY=false
DRY_RUN=false
JSON=false
WRITE_LOG=false

usage() {
  sed -n '2,16p' "$0" | tail -n +2
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --tier) TIER="${2:-}"; shift 2 ;;
    --behavior) BEHAVIOR_OVERRIDE="${2:-}"; shift 2 ;;
    --apply) APPLY=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json) JSON=true; shift ;;
    --write-log-snippet) WRITE_LOG=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

if [[ -z "$REPO" ]]; then
  if git -C "$ROOT" rev-parse --show-toplevel &>/dev/null; then
    REPO="$(git -C "$ROOT" rev-parse --show-toplevel)"
  else
    REPO="$ROOT"
  fi
fi
REPO="$(cd "$REPO" && pwd)"

case "$TIER" in
  minimal|standard|full|auto) ;;
  *) echo "FAIL: --tier must be minimal|standard|full|auto" >&2; exit 1 ;;
esac

case "$BEHAVIOR_OVERRIDE" in
  ""|superpowers|gstack|none) ;;
  *) echo "FAIL: --behavior must be superpowers|gstack|none" >&2; exit 1 ;;
esac

SOURCE_EXTS='\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|java|kt|kts|swift|rb|cs|cpp|cc|c|h|hpp|vue|svelte|php|scala|dart|lua|zig)$'

list_repo_files() {
  if git -C "$REPO" rev-parse --is-inside-work-tree &>/dev/null; then
    git -C "$REPO" ls-files -z
  else
    find "$REPO" -type f \
      ! -path '*/.git/*' \
      ! -path '*/node_modules/*' \
      ! -path '*/vendor/*' \
      ! -path '*/dist/*' \
      ! -path '*/build/*' \
      ! -path '*/.venv/*' \
      -print0
  fi
}

count_matching() {
  local pattern="$1"
  local n=0
  while IFS= read -r -d '' f; do
    rel="${f#"$REPO"/}"
    [[ "$rel" == "$f" ]] && rel="${f#"$REPO"/*}"
    if [[ "$rel" =~ $pattern ]]; then
      n=$((n + 1))
    fi
  done < <(list_repo_files)
  echo "$n"
}

path_exists() {
  [[ -e "$REPO/$1" ]]
}

SOURCE_FILES="$(count_matching "$SOURCE_EXTS")"
DOC_FILES="$(count_matching '\.md$')"
TRACKED_FILES=0
while IFS= read -r -d '' _; do TRACKED_FILES=$((TRACKED_FILES + 1)); done < <(list_repo_files)

HAS_HARNESS=false
path_exists ".cursor/rules/orchestrator.mdc" && HAS_HARNESS=true

HAS_PACKAGE=false
path_exists "package.json" && HAS_PACKAGE=true

HAS_FRONTEND=false
for d in frontend client apps/web apps/frontend web; do
  path_exists "$d" && HAS_FRONTEND=true && break
done

HAS_BACKEND=false
for d in backend server modules api; do
  path_exists "$d" && HAS_BACKEND=true && break
done

HAS_DOCKER=false
if path_exists "Dockerfile" || path_exists "docker-compose.yml" || path_exists "compose.yaml"; then
  HAS_DOCKER=true
fi

HAS_E2E=false
if path_exists "playwright.config.ts" || path_exists "playwright.config.js" || path_exists "cypress.config.ts"; then
  HAS_E2E=true
fi
if [[ "$HAS_E2E" == false ]] && path_exists "e2e"; then HAS_E2E=true; fi

HAS_WORKSPACES=false
path_exists "pnpm-workspace.yaml" || path_exists "lerna.json" && HAS_WORKSPACES=true
if [[ "$HAS_WORKSPACES" == false ]] && path_exists "packages"; then HAS_WORKSPACES=true; fi

PROFILE="app"
if [[ "$SOURCE_FILES" -lt 30 && "$DOC_FILES" -ge 5 ]]; then
  PROFILE="doc-only"
fi
if [[ "$SOURCE_FILES" -ge 200 || "$TRACKED_FILES" -ge 800 || "$HAS_WORKSPACES" == true ]]; then
  PROFILE="large"
fi

if [[ "$TIER" == "auto" ]]; then
  case "$PROFILE" in
    doc-only) TIER="minimal" ;;
    large) TIER="standard" ;;
    *) TIER="standard" ;;
  esac
fi

BEHAVIOR="none"
if [[ -n "$BEHAVIOR_OVERRIDE" ]]; then
  BEHAVIOR="$BEHAVIOR_OVERRIDE"
else
  if [[ "$TIER" != "minimal" ]]; then
    if [[ "$HAS_DOCKER" == true || "$HAS_E2E" == true ]]; then
      BEHAVIOR="gstack"
    elif [[ "$SOURCE_FILES" -ge 20 ]]; then
      BEHAVIOR="superpowers"
    elif [[ "$PROFILE" == "doc-only" ]]; then
      BEHAVIOR="superpowers"
    fi
  fi
fi

declare -A REC_ACTION REC_REASON REC_INSTALL
# action: install | manual | skip

set_rec() {
  local id="$1" action="$2" reason="$3" install="${4:-}"
  REC_ACTION["$id"]="$action"
  REC_REASON["$id"]="$reason"
  REC_INSTALL["$id"]="$install"
}

# --- recommendations ---
set_rec claude-mem install "TB·handoff 맥락 유지 (레이어 A)" "npx claude-mem install"

if [[ "$BEHAVIOR" == "superpowers" ]]; then
  set_rec superpowers manual "설계·TDD·리뷰 (레이어 B). 하네스 dispatch와 역할 분리 필요" "Cursor: /add-plugin superpowers"
  set_rec gstack skip "행동 레이어는 superpowers 로 택일" ""
elif [[ "$BEHAVIOR" == "gstack" ]]; then
  set_rec gstack manual "배포·브라우저 QA (레이어 B). checkpoint 커밋 규칙 확인" "git clone gstack → ~/.cursor/skills/gstack && ./setup --host cursor"
  set_rec superpowers skip "행동 레이어는 gstack 으로 택일" ""
else
  set_rec superpowers skip "tier=$TIER — 행동 레이어 생략" ""
  set_rec gstack skip "tier=$TIER — 행동 레이어 생략" ""
fi

if [[ "$SOURCE_FILES" -ge 20 && "$TIER" != "minimal" ]]; then
  set_rec code-review-graph install "리뷰·blast radius (레이어 A)" "pip install code-review-graph && code-review-graph install --platform cursor && code-review-graph build"
  set_rec ponytail manual "과잉 구현 방지 (레이어 C). .mdc 와 병합 — orchestrator 덮어쓰지 않음" "cp upstream .cursor/rules/ponytail*.mdc → .cursor/rules/"
else
  set_rec code-review-graph skip "소스 파일 ${SOURCE_FILES}개 — doc-only 또는 코드베이스 미성숙" ""
  set_rec ponytail skip "코드베이스 없음 또는 소스 ${SOURCE_FILES}개" ""
fi

if [[ "$PROFILE" == "large" && "$TIER" == "full" ]]; then
  set_rec headroom install "대형 repo tool output 압축 (레이어 A)" "pip install 'headroom-ai[all]' && headroom doctor"
elif [[ "$PROFILE" == "large" && "$TIER" == "standard" ]]; then
  set_rec headroom manual "대형 repo — 필요 시 headroom proxy/MCP" "pip install 'headroom-ai[all]' && headroom doctor"
else
  set_rec headroom skip "PROFILE=$PROFILE — headroom ROI 낮음" ""
fi

if [[ "$PROFILE" == "doc-only" ]]; then
  set_rec caveman skip "Editor 문서 품질 우선 — caveman 비추" ""
else
  if [[ "$TIER" == "full" ]]; then
    set_rec caveman install "Backend/Frontend 응답 prose 압축 (레이어 C)" "npx skills add JuliusBrussee/caveman -a cursor"
  else
    set_rec caveman skip "standard/minimal — caveman 선택 사항" ""
  fi
fi

if [[ "$TIER" == "full" && "$DOC_FILES" -ge 10 ]]; then
  set_rec agency-agents manual "문서·QA 페르소나 subset (레이어 D). .mdc 대체 금지" "./scripts/install.sh --tool cursor --agent technical-writer,qa-engineer"
else
  set_rec agency-agents skip "tier=$TIER 또는 문서량 부족" ""
fi

# tier=minimal: only claude-mem + optional superpowers manual hint
if [[ "$TIER" == "minimal" ]]; then
  set_rec code-review-graph skip "minimal tier" ""
  set_rec ponytail skip "minimal tier" ""
  set_rec headroom skip "minimal tier" ""
  set_rec caveman skip "minimal tier" ""
  set_rec agency-agents skip "minimal tier" ""
  if [[ "$BEHAVIOR" == "superpowers" ]]; then
    set_rec superpowers manual "doc-only 선택: 설계·QA 강화" "Cursor: /add-plugin superpowers"
  fi
fi

# tier=full: upgrade skips where we had manual only
if [[ "$TIER" == "full" ]]; then
  if [[ "$SOURCE_FILES" -ge 20 ]]; then
    REC_ACTION[code-review-graph]="install"
  fi
  if [[ "$PROFILE" == "large" ]]; then
    REC_ACTION[headroom]="install"
  fi
  if [[ "$PROFILE" != "doc-only" ]]; then
    REC_ACTION[caveman]="install"
  fi
fi

print_profile() {
  echo "==> Repo profile ($REPO)"
  echo "    profile:     $PROFILE"
  echo "    tier:        $TIER (requested: auto → resolved)"
  echo "    behavior:    $BEHAVIOR"
  echo "    harness:     $HAS_HARNESS"
  echo "    source files: $SOURCE_FILES"
  echo "    doc (.md):   $DOC_FILES"
  echo "    tracked:     $TRACKED_FILES"
  echo "    stack hints: package.json=$HAS_PACKAGE frontend=$HAS_FRONTEND backend=$HAS_BACKEND"
  echo "    deploy/qa:   docker=$HAS_DOCKER e2e=$HAS_E2E workspaces=$HAS_WORKSPACES"
  echo ""
}

print_recommendations() {
  echo "==> Recommendations (docs/harness/third-party-plugins.md)"
  local ids=(claude-mem superpowers gstack code-review-graph headroom ponytail caveman agency-agents)
  for id in "${ids[@]}"; do
    local action="${REC_ACTION[$id]:-skip}"
    local reason="${REC_REASON[$id]:-}"
    local install="${REC_INSTALL[$id]:-}"
    printf "  [%s] %-18s %s\n" "$action" "$id" "$reason"
    if [[ -n "$install" && "$action" != "skip" ]]; then
      echo "         → $install"
    fi
  done
  echo ""
}

run_cmd() {
  local desc="$1"
  shift
  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] $desc"
    printf '            '
    printf '%q ' "$@"
    echo ""
    return 0
  fi
  echo "  [run] $desc"
  if "$@"; then
    echo "  [ok] $desc"
  else
    echo "  [warn] failed: $desc (continuing)" >&2
    return 0
  fi
}

has_cmd() { command -v "$1" &>/dev/null; }

apply_installs() {
  echo "==> Apply"
  if [[ "$APPLY" == false ]]; then
    echo "  (no --apply — showing commands only; use --apply --dry-run to preview runs)"
    DRY_RUN=true
  fi

  for id in claude-mem code-review-graph headroom caveman; do
    [[ "${REC_ACTION[$id]:-skip}" == "install" ]] || continue
    case "$id" in
      claude-mem)
        has_cmd npx || { echo "  [skip] claude-mem — npx not found" >&2; continue; }
        run_cmd "claude-mem install" npx --yes claude-mem install
        echo "  [note] Cursor hooks: see claude-mem cursor-hooks/ → ~/.cursor/hooks.json"
        ;;
      code-review-graph)
        local pip_cmd=""
        for c in pip3 pip; do has_cmd "$c" && pip_cmd="$c" && break; done
        [[ -n "$pip_cmd" ]] || { echo "  [skip] code-review-graph — pip not found" >&2; continue; }
        run_cmd "pip install code-review-graph" "$pip_cmd" install code-review-graph
        if has_cmd code-review-graph; then
          run_cmd "CRG cursor MCP" code-review-graph install --platform cursor
          (cd "$REPO" && run_cmd "CRG build" code-review-graph build)
        fi
        echo "  [note] Add MCP per docs/harness/mcp-setup.md (.cursor/mcp.json, do not commit)"
        ;;
      headroom)
        local pip_cmd=""
        for c in pip3 pip; do has_cmd "$c" && pip_cmd="$c" && break; done
        [[ -n "$pip_cmd" ]] || { echo "  [skip] headroom — pip not found" >&2; continue; }
        run_cmd "pip install headroom-ai" "$pip_cmd" install "headroom-ai[all]"
        if has_cmd headroom; then
          run_cmd "headroom doctor" headroom doctor
        fi
        echo "  [note] Cursor: manual proxy/MCP — headroom wrap cursor or mcp.json"
        ;;
      caveman)
        has_cmd npx || { echo "  [skip] caveman — npx not found" >&2; continue; }
        run_cmd "caveman skill" npx --yes skills add JuliusBrussee/caveman -a cursor
        ;;
    esac
  done

  echo ""
  echo "==> Manual steps (cannot fully automate)"
  for id in superpowers gstack ponytail agency-agents; do
    [[ "${REC_ACTION[$id]:-skip}" == "manual" ]] || continue
    echo "  • $id: ${REC_INSTALL[$id]}"
  done
  echo ""
  echo "==> After install"
  echo "  1. Record adoption in docs/harness/alignment-log.md (--write-log-snippet)"
  echo "  2. ./scripts/doc-quality-gate.sh && ./scripts/validate-harness.sh"
}

write_log_snippet() {
  local date
  date="$(date +%Y-%m-%d)"
  echo ""
  echo "==> alignment-log.md snippet (paste under ## 서드파티 채택)"
  cat <<EOF
### Plugin recommend — $date

| 도구 | action | profile=$PROFILE tier=$TIER behavior=$BEHAVIOR |
|------|--------|-----------------------------------------------|
EOF
  for id in claude-mem superpowers gstack code-review-graph headroom ponytail caveman agency-agents; do
    printf '| %s | %s | %s |\n' "$id" "${REC_ACTION[$id]:-skip}" "${REC_REASON[$id]:-}"
  done
  echo ""
  echo "우선순위: TB 티켓·\`.mdc\` > ${BEHAVIOR:-none} > 레이어 C 스킬."
}

emit_json() {
  local ids=(claude-mem superpowers gstack code-review-graph headroom ponytail caveman agency-agents)
  local parts=()
  parts+=("\"repo\":\"${REPO//\"/\\\"}\"")
  parts+=("\"profile\":\"$PROFILE\"")
  parts+=("\"tier\":\"$TIER\"")
  parts+=("\"behavior\":\"$BEHAVIOR\"")
  parts+=("\"source_files\":$SOURCE_FILES")
  local rec_parts=()
  for id in "${ids[@]}"; do
    rec_parts+=("\"$id\":{\"action\":\"${REC_ACTION[$id]:-skip}\",\"reason\":\"${REC_REASON[$id]:-//}\"}")
  done
  local rec_json
  rec_json=$(IFS=,; echo "${rec_parts[*]}")
  echo "{${parts[*]},\"recommendations\":{${rec_json}}}"
}

print_profile
print_recommendations
apply_installs
[[ "$WRITE_LOG" == true ]] && write_log_snippet
[[ "$JSON" == true ]] && emit_json
