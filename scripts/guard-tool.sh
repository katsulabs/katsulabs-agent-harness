#!/usr/bin/env bash
# 에이전트 훅 (PreToolUse) — 실행 시점 강제. Claude Code 호환 (stdin JSON, exit 2 = 차단)
# 차단: main 직접 커밋/푸시 · HARNESS_ROLE 범위 밖 편집
# 의존: bash, jq, git
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
input="$(cat)"
command -v jq >/dev/null 2>&1 || { echo "guard-tool: jq 필요 — 가드 생략" >&2; exit 0; }

tool="$(jq -r '.tool_name // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[[ -n "$cwd" && -d "$cwd" ]] || cwd="$ROOT"
branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"

deny() { echo "BLOCKED(harness): $1" >&2; exit 2; }

case "$tool" in
  Bash)
    cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
    # git 하위 명령 단위로 검사 (; && || | 로 분리)
    while IFS= read -r seg; do
      seg="${seg#"${seg%%[![:space:]]*}"}"
      [[ "$seg" =~ ^git[[:space:]] ]] || continue
      if [[ "$seg" =~ ^git[[:space:]]+(commit|merge|rebase|cherry-pick|revert)([[:space:]]|$) ]] && [[ "$branch" == "main" ]]; then
        deny "main 직접 커밋/머지 금지 — feature/TB-{id}-{name} 브랜치에서 작업 (AGENTS.md)"
      fi
      if [[ "$seg" =~ ^git[[:space:]]+push ]]; then
        if [[ "$branch" == "main" ]] || [[ "$seg" =~ (^|[[:space:]:])main($|[[:space:]]) ]]; then
          deny "main 직접 push 금지 — PR로 머지 (AGENTS.md)"
        fi
        [[ "$seg" =~ (--force|[[:space:]]-f([[:space:]]|$)) ]] && deny "force push 금지"
      fi
    done < <(sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$cmd")
    ;;
  Edit|Write|NotebookEdit|MultiEdit)
    role="${HARNESS_ROLE:-}"
    [[ -z "$role" ]] && exit 0                     # 역할 미지정(메인 세션)은 통과
    file="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")"
    [[ -z "$file" ]] && exit 0
    # 심볼릭 경로 차이(macOS /var → /private/var) 대비: 여러 접두사 시도
    # Windows(Git Bash): C:\x, C:/x, /c/x 형태가 섞이므로 모두 C:/x 로 정규화
    norm() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1" 2>/dev/null || echo "${1//\\//}"; else echo "${1//\\//}"; fi; }
    file="$(norm "$file")"
    rel="$file"
    for top in "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" "$(cd "$cwd" && pwd)" "$(cd "$cwd" && pwd -P)" "$ROOT"; do
      [[ -n "$top" ]] || continue
      top="$(norm "$top")"
      [[ "$file" == "$top"/* ]] && { rel="${file#"$top"/}"; break; }
    done
    scopes="$(jq -r --arg r "$role" '.[$r] // empty | .[]' "$ROOT/scripts/role-scopes.json" 2>/dev/null | tr -d '\r')"
    [[ -z "$scopes" ]] && deny "알 수 없는 HARNESS_ROLE='$role' (scripts/role-scopes.json)"
    ok=false
    while IFS= read -r g; do
      # glob → 정규식: ** = 임의, * = 슬래시 제외
      re="$(sed -E 's#\.#\\.#g; s#\*\*/#\x01#g; s#\*\*#\x02#g; s#\*#[^/]*#g; s#\x01#(.*/)?#g; s#\x02#.*#g' <<<"$g")"
      [[ "$rel" =~ ^${re}$ ]] && { ok=true; break; }
    done <<<"$scopes"
    $ok || deny "[$role] 범위 밖 편집: $rel (허용: $(tr '\n' ' ' <<<"$scopes"))"
    ;;
esac
exit 0
