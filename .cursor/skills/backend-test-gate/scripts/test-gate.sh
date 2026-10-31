#!/usr/bin/env bash
# Backend test gate: did backend paths change? If so, run tests and print a PR-ready result line.
# Standalone: git + bash + your test runner.
# Usage: test-gate.sh [--force]        (--force: run tests even if no backend path changed)
# Env:   BACKEND_PATHS (space-separated, default "modules backend server api")  BASE  TEST_CMD
set -uo pipefail
TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "FAIL: not inside a git repository"; exit 1; }
cd "$TOP"
PATHS="${BACKEND_PATHS:-modules backend server api}"
FORCE=false; [[ "${1:-}" == "--force" ]] && FORCE=true

default_branch() {
  local b
  b="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')" || true
  [[ -n "$b" ]] && { echo "$b"; return; }
  for c in main master; do git show-ref --verify --quiet "refs/heads/$c" && { echo "$c"; return; }; done
  echo main
}
detect_test_cmd() {
  if [[ -n "${TEST_CMD:-}" ]]; then echo "$TEST_CMD"
  elif [[ -f package.json ]] && grep -q '"test"' package.json; then echo "npm test"
  elif [[ -x ./gradlew ]]; then echo "./gradlew test"
  elif [[ -f pom.xml ]]; then echo "mvn -q test"
  elif [[ -f go.mod ]]; then echo "go test ./..."
  elif [[ -f Cargo.toml ]]; then echo "cargo test"
  elif [[ -f pytest.ini || -f pyproject.toml || -d tests ]] && command -v pytest >/dev/null 2>&1; then echo "pytest -q"
  elif [[ -f Makefile ]] && grep -qE '^test:' Makefile; then echo "make test"
  fi
}

def="$(default_branch)"
base="${BASE:-}"
if [[ -z "$base" ]]; then
  if git show-ref --verify --quiet "refs/remotes/origin/$def"; then base="origin/$def"; else base="$def"; fi
fi
changed="$( { git diff --name-only "$base"...HEAD 2>/dev/null; git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard; } | sort -u )"

touched=()
for p in $PATHS; do
  hit="$(grep -E "^${p%/}/" <<<"$changed" || true)"
  [[ -n "$hit" ]] && touched+=("$p")
done

echo "test-gate: base=$base paths=[$PATHS]"
if [[ ${#touched[@]} -eq 0 && "$FORCE" == false ]]; then
  echo "SKIP: no backend path changed (use --force to run anyway)"
  echo "PR line: Backend test gate: skipped (no backend changes)"
  exit 0
fi
[[ ${#touched[@]} -gt 0 ]] && echo "backend paths changed: ${touched[*]}"

# contract sync warning: DTO / API spec / migration changed but no handoff doc touched
if grep -qiE '(dto|openapi|api-spec|contracts?|migration|/db/)' <<<"$changed"; then
  if ! grep -qiE 'handoff' <<<"$changed"; then
    echo "WARN: API/DTO/DB files changed but no handoff document was updated (contract-handoff skill)"
  fi
fi

cmd="$(detect_test_cmd)"
if [[ -z "$cmd" ]]; then
  echo "FAIL: no test command detected — set TEST_CMD"
  echo "PR line: Backend test gate: FAIL (no test command)"
  exit 1
fi
echo "running: $cmd"
if bash -c "$cmd"; then
  echo "PASS: test-gate"
  echo "PR line: Backend test gate: PASS ($cmd)"
  exit 0
fi
echo "FAIL: test-gate"
echo "PR line: Backend test gate: FAIL ($cmd)"
exit 1
