#Requires -Version 7.4
<#
.SYNOPSIS
  Harness Gate — 링크·규칙·일관성·템플릿 자동 검증 (PowerShell 7.4+)
.EXAMPLE
  pwsh scripts/validate-harness.ps1
.EXAMPLE
  pwsh scripts/validate-harness.ps1 -Pr
.NOTES
  macOS/Linux/Git Bash: ./scripts/validate-harness.sh
  Setup: docs/harness/setup-shell.md
#>
param([switch]$Pr)

. "$PSScriptRoot/shell-env.ps1"
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$failures = [System.Collections.Generic.List[string]]::new()

function Fail([string]$msg) { $failures.Add($msg) }

$staleRefs = @(
    'agent-hierarchy.md', 'workflow.md', 'reference-baseline.md',
    'doc-link-validation', 'cursor-rule-validation', 'doc-consistency', 'pr-quality-gate'
)

# --- 1. 링크 ---
$mdFiles = Get-ChildItem -Recurse -Filter '*.md' -File |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

$linkPattern = '\[[^\]]*\]\(([^)]+)\)'
foreach ($file in $mdFiles) {
    $dir = $file.DirectoryName
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($m in [regex]::Matches($content, $linkPattern)) {
        $target = $m.Groups[1].Value.Trim()
        if ($target -match '^(https?://|mailto:|#)') { continue }
        $target = $target -replace '#.*$', ''
        if ([string]::IsNullOrWhiteSpace($target)) { continue }
        $resolved = if ($target.StartsWith('/')) {
            Join-Path $root ($target.TrimStart('/'))
        } else {
            Join-Path $dir $target
        }
        $resolved = [System.IO.Path]::GetFullPath($resolved)
        if (-not (Test-Path -LiteralPath $resolved)) {
            $rel = $file.FullName.Substring($root.Length + 1)
            Fail "BROKEN_LINK: $rel -> $target"
        }
    }
}

# --- 2. 구 참조·playbook 포맷 ---
foreach ($file in $mdFiles) {
    $rel = $file.FullName.Substring($root.Length + 1)
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($stale in $staleRefs) {
        if ($content -match [regex]::Escape($stale)) {
            Fail "STALE_REF: $rel — '$stale' 참조"
        }
    }
    if ($rel -eq 'docs/harness/playbook.md') {
        if ($content -match '(\r?\n){3,}') {
            Fail "FORMAT: playbook.md — 연속 빈 줄 3개 이상"
        }
        if (($content -split '(?m)^# ').Count -gt 2) {
            Fail "FORMAT: playbook.md — h1은 1개만"
        }
    }
}

# --- 3. 규칙 (.mdc) ---
$mdcDir = Join-Path $root '.cursor/rules'
$alwaysApplyTrue = @()
if (Test-Path $mdcDir) {
    foreach ($mdc in Get-ChildItem -Path $mdcDir -Filter '*.mdc') {
        $text = Get-Content -LiteralPath $mdc.FullName -Raw
        $name = $mdc.Name
        if (-not $text.StartsWith("---`n") -and -not $text.StartsWith("---`r`n")) {
            Fail "MDC_FORMAT: $name — front-matter 누락"
            continue
        }
        if ($text -notmatch '(?m)^description:\s*.+') { Fail "MDC_FIELD: $name — description 누락" }
        if ($text -notmatch '(?m)^alwaysApply:\s*(true|false)') { Fail "MDC_FIELD: $name — alwaysApply 누락" }
        if ($text -match '(?m)^alwaysApply:\s*true') {
            $alwaysApplyTrue += $name
            if ($text -notmatch '(?m)^#\s') { Fail "MDC_BODY: $name — 제목 누락" }
        } else {
            if ($text -notmatch '(?m)^globs:\s*.+') { Fail "MDC_FIELD: $name — globs 누락" }
        }
    }
    if ($alwaysApplyTrue.Count -ne 1 -or $alwaysApplyTrue[0] -ne 'orchestrator.mdc') {
        Fail "MDC_POLICY: alwaysApply:true는 orchestrator.mdc만 (현재: $($alwaysApplyTrue -join ', '))"
    }
}

# --- 4. 역할 규칙 ↔ playbook 범위 ---
$playbookPath = Join-Path $root 'docs/harness/playbook.md'
$roleScopes = @{
    'editor.mdc'    = @('docs/**', '.cursor/**', '.github/**')
    'contract.mdc'  = @('db/**', '**/dto/**', '**/openapi.*', 'contracts/**', 'api-spec/**')
    'backend.mdc'   = @('modules/**', 'backend/**', 'server/**', 'api/**')
    'frontend.mdc'  = @('frontend/**', 'client/**', 'apps/web/**')
}
if (Test-Path $playbookPath) {
    $pb = Get-Content -LiteralPath $playbookPath -Raw
    foreach ($entry in $roleScopes.GetEnumerator()) {
        $mdcPath = Join-Path $mdcDir $entry.Key
        if (-not (Test-Path $mdcPath)) {
            Fail "MISSING: .cursor/rules/$($entry.Key)"
            continue
        }
        $mdc = Get-Content -LiteralPath $mdcPath -Raw
        foreach ($scope in $entry.Value) {
            $esc = [regex]::Escape($scope)
            if ($pb -notmatch $esc -or $mdc -notmatch $esc) {
                Fail "SCOPE_SYNC: $($entry.Key) ↔ playbook.md — '$scope' 불일치"
            }
        }
    }
}

# --- 5. PR 템플릿 ---
$prTpl = Join-Path $root '.github/PULL_REQUEST_TEMPLATE.md'
if (Test-Path $prTpl) {
    $tpl = Get-Content -LiteralPath $prTpl -Raw
    foreach ($section in @('## 요약', '## 검증 계획', '## 테스트 게이트', '## 하드 게이트')) {
        if ($tpl -notmatch [regex]::Escape($section)) {
            Fail "PR_TEMPLATE: 필수 섹션 누락 — $section"
        }
    }
} else {
    Fail "MISSING: .github/PULL_REQUEST_TEMPLATE.md"
}

# --- 6. 일관성 ---
if (-not (Test-Path $playbookPath)) {
    Fail "MISSING: docs/harness/playbook.md"
} else {
    $pb = Get-Content -LiteralPath $playbookPath -Raw
    foreach ($role in @('Main', 'Editor', 'Contract', 'Backend', 'Frontend', 'QA')) {
        if ($pb -notmatch $role) { Fail "CONSISTENCY: playbook.md에 '$role' 없음" }
    }
    foreach ($mdc in @('contract.mdc', 'backend.mdc', 'frontend.mdc')) {
        if (-not (Test-Path (Join-Path $mdcDir $mdc))) {
            Fail "MISSING: .cursor/rules/$mdc"
        }
    }
}

$skill = Join-Path $root '.cursor/skills/harness-gate/SKILL.md'
if (-not (Test-Path $skill)) { Fail "MISSING: .cursor/skills/harness-gate/SKILL.md" }

$workflow = Join-Path $root '.github/workflows/harness-gate.yml'
if (-not (Test-Path $workflow)) { Fail "MISSING: .github/workflows/harness-gate.yml" }
elseif ((Get-Content $workflow -Raw) -notmatch 'test:') { Fail "CI: test job 누락" }

# --- 6b. 3세대 필수 파일 ---
foreach ($f in @(
    'AGENTS.md', 'CONTRIBUTING.md', 'docs/harness/TEMPLATE.md',
    'scripts/run-eval.ps1', 'scripts/run-eval.sh',
    'scripts/validate-harness.sh', 'docs/harness/setup-shell.md',
    '.cursor/mcp.json.example', 'docs/harness/examples/sample-ticket-code.md',
    'eval/harness-smoke.ps1', 'eval/harness-smoke.sh',
    'eval/agent-smoke.checklist.md', 'eval/reports/README.md',
    'docs/harness/handoff-schema.md', 'docs/harness/mcp-setup.md',
    'scripts/validate-handoff.ps1', 'scripts/validate-handoff.sh',
    'scripts/validate-status.ps1', 'scripts/validate-status.sh',
    'scripts/dispatch-plan.ps1', 'scripts/dispatch-plan.sh',
    'scripts/collect-handoff.ps1', 'scripts/collect-handoff.sh',
    'docs/harness/status-schema.md', 'docs/harness/examples/status-example.md',
    'docs/harness/examples/status-complete.md',
    'scripts/run-agent-eval.ps1', 'scripts/run-agent-eval.sh',
    'scripts/dispatch-prompt.ps1', 'scripts/dispatch-prompt.sh',
    'scripts/summarize-eval.ps1', 'scripts/summarize-eval.sh',
    'sample/package.json', 'sample/server/users.test.js',
    'docs/harness/secrets.md', 'docs/harness/agent-llm-eval.md',
    'scripts/run-agent-llm-eval.ps1', 'scripts/run-agent-llm-eval.sh',
    'scripts/score-agent-llm.ps1', 'scripts/score-agent-llm.sh',
    'scripts/cost-summary.ps1', 'scripts/cost-summary.sh',
    'scripts/verify-dispatch.ps1', 'scripts/verify-dispatch.sh',
    'docs/harness/secrets-rotation.md',
    'eval/agent-tasks/expected/al-01.json',
    'docs/harness/first-ticket.md', 'docs/harness/presets/node.md',
    'docs/harness/handoffs/README.md',
    'scripts/validate-commit-msg.ps1', 'scripts/validate-todo-sync.ps1',
    'scripts/validate-pr-body.ps1',     'scripts/validate-staged-handoff.ps1',
    'docs/harness/glossary.md', 'docs/harness/eval-guide.md',
    'docs/harness/scripts-reference.md',
    'CLAUDE.md', '.claude/settings.json', 'scripts/role-scopes.json',
    'scripts/guard-tool.sh', 'scripts/stop-gate.sh', 'scripts/sync-adapters.sh',
    'scripts/context-budget.sh', 'scripts/run-llm-ci.sh', 'scripts/llm-cost.sh',
    'docs/harness/modernization.md', '.github/workflows/llm-eval.yml',
    'eval/skills-standalone.test.sh', 'scripts/package-skills.sh',
    '.cursor/skills/dispatch/scripts/dispatch-plan.sh', '.cursor/skills/harness-gate/scripts/gate.sh'
)) {
    if (-not (Test-Path (Join-Path $root $f))) { Fail "MISSING: $f" }
}
$agents = Get-Content (Join-Path $root 'AGENTS.md') -Raw
if ($agents -match '문서 전용') { Fail "AGENTS.md: 코드 저장소 계약으로 갱신 필요" }

foreach ($skill in @('harness-gate', 'pr-workflow', 'worktree-setup', 'dispatch', 'contract-handoff', 'backend-test-gate')) {
    if (-not (Test-Path (Join-Path $root ".cursor/skills/$skill/SKILL.md"))) {
        Fail "MISSING: .cursor/skills/$skill/SKILL.md"
    }
}

# --- 6c. 도구 중립 어댑터 (.cursor/skills ↔ .claude/skills) ---
foreach ($skill in @('harness-gate', 'pr-workflow', 'worktree-setup', 'dispatch', 'contract-handoff', 'backend-test-gate')) {
    $src = Join-Path $root ".cursor/skills/$skill/SKILL.md"
    $dst = Join-Path $root ".claude/skills/$skill/SKILL.md"
    if (-not (Test-Path $dst) -or (Get-FileHash $src).Hash -ne (Get-FileHash $dst).Hash) {
        Fail "ADAPTER: .claude/skills/$skill 불일치 — scripts/sync-adapters.sh 실행"
    }
}
if (-not ((Get-Content (Join-Path $root 'CLAUDE.md') -Raw -ErrorAction SilentlyContinue) -match '@AGENTS\.md')) {
    Fail "ADAPTER: CLAUDE.md 는 @AGENTS.md 를 import 해야 함"
}

# --- 7. PR 모드 ---
if ($Pr) {
    $branch = (git branch --show-current 2>$null)
    if ($branch -eq 'main') { Fail "PR_BRANCH: main에서 PR 불가" }
    $commits = git log main..HEAD --oneline 2>$null
    if (-not $commits) { Fail "PR_COMMITS: main 대비 커밋 없음" }
    & pwsh -NoProfile -File (Join-Path $root 'scripts/verify-dispatch.ps1')
    if ($LASTEXITCODE -ne 0) { Fail "DISPATCH: verify-dispatch 실패" }
    & pwsh -NoProfile -File (Join-Path $root 'scripts/validate-todo-sync.ps1')
    if ($LASTEXITCODE -ne 0) { Fail "TODO_SYNC: validate-todo-sync 실패" }
    & pwsh -NoProfile -File (Join-Path $root 'scripts/validate-commit-msg.ps1') -Pr
    if ($LASTEXITCODE -ne 0) { Fail "COMMIT: validate-commit-msg 실패" }
}

# --- 결과 ---
$mdcCount = @(Get-ChildItem $mdcDir -Filter '*.mdc' -ErrorAction SilentlyContinue).Count
if ($failures.Count -eq 0) {
    Write-Host "PASS: harness-gate ($($mdFiles.Count) md, $mdcCount mdc)"
    exit 0
}

Write-Host "FAIL: harness-gate ($($failures.Count) issues)"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
