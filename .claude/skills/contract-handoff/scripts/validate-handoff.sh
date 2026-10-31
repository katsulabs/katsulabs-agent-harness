#!/usr/bin/env bash
# Lint contract handoff documents. Standalone: bash only.
# Usage: validate-handoff.sh [file ...]     (default: every *.md in the handoff dir except README and *-status.md)
# Env:   HANDOFF_DIR (default: docs/harness/handoffs if it exists, else docs/handoffs)
# Accepts Korean or English section headings.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

dir="${HANDOFF_DIR:-}"
if [[ -z "$dir" ]]; then if [[ -d docs/harness/handoffs ]]; then dir=docs/harness/handoffs; else dir=docs/handoffs; fi; fi

# each entry: "Korean heading|English heading"
sections=(
  '## API 변경|## API changes'
  '## DTO|## DTO'
  '## DB|## DB'
  '## Backend TODO|## Backend TODO'
  '## Frontend TODO|## Frontend TODO'
  '## Breaking change|## Breaking change'
)
failures=()
fail() { failures+=("$1"); }

check_file() {
  local f="$1" fm key val s ko en
  [[ -f "$f" ]] || { fail "MISSING: $f"; return; }
  [[ "$(head -n 1 "$f")" == "---" ]] || { fail "FRONTMATTER: $f — must start with '---'"; return; }
  fm="$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")"
  for key in ticket from to status breaking; do
    grep -qE "^${key}:" <<<"$fm" || fail "FRONTMATTER: $f — '${key}:' missing"
  done
  val="$(sed -nE 's/^status:[[:space:]]*//p' <<<"$fm" | head -n1)"
  [[ -z "$val" || "$val" == "ready" || "$val" == "blocked" ]] || fail "FRONTMATTER: $f — status must be ready|blocked (got '$val')"
  val="$(sed -nE 's/^breaking:[[:space:]]*//p' <<<"$fm" | head -n1)"
  [[ -z "$val" || "$val" == "true" || "$val" == "false" ]] || fail "FRONTMATTER: $f — breaking must be true|false (got '$val')"
  for s in "${sections[@]}"; do
    ko="${s%%|*}"; en="${s##*|}"
    grep -qxF "$ko" "$f" || grep -qxF "$en" "$f" || fail "SECTION: $f — '$ko' (or '$en') missing"
  done
}

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  if [[ -d "$dir" ]]; then
    while IFS= read -r f; do
      case "$(basename "$f")" in README.md|*-status.md) continue ;; esac
      targets+=("$f")
    done < <(find "$dir" -name '*.md' -type f | sort)
  fi
fi
if [[ ${#targets[@]} -eq 0 ]]; then echo "PASS: validate-handoff (no handoff files in $dir)"; exit 0; fi

for t in "${targets[@]}"; do check_file "$t"; done
if [[ ${#failures[@]} -eq 0 ]]; then echo "PASS: validate-handoff (${#targets[@]} file(s))"; exit 0; fi
echo "FAIL: validate-handoff (${#failures[@]} issue(s))"
printf '  - %s\n' "${failures[@]}"
exit 1
