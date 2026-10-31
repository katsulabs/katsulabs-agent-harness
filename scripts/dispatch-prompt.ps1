#Requires -Version 7.4
<#
.SYNOPSIS
  서브에이전트 디스패치 프롬프트 생성.
.EXAMPLE
  pwsh scripts/dispatch-prompt.ps1 -Ticket TB-101 -Role Contract
#>
param(
    [Parameter(Mandatory)][string]$Ticket,
    [Parameter(Mandatory)][ValidateSet('Editor', 'Contract', 'Backend', 'Frontend', 'QA')][string]$Role
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$scopes = @{
    Editor   = 'docs/**, .cursor/**, .github/**'
    Contract = 'db/**, **/dto/**, contracts/**, api-spec/**'
    Backend  = 'modules/**, backend/**, server/**, api/**'
    Frontend = 'frontend/**, client/**, apps/web/**'
    QA       = 'validate-harness, run-eval, CI'
}

$directives = @{
    Editor   = '문서·규칙·PR 템플릿만 수정. 요청 범위 밖 diff 금지.'
    Contract = 'API/DTO/DB 계약을 handoff-schema.md 형식으로 고정. 구현 코드 작성 금지.'
    Backend  = 'Contract 핸드오프 확인 후 서버·API 구현. 계약 변경 시 Contract에 역보고.'
    Frontend = 'Contract 핸드오프 확인 후 UI 구현. API 타입 동기화.'
    QA       = 'validate-harness -Pr + run-eval + PR 본문·eval 리포트 요약.'
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("[$Ticket][$Role]")
$lines.Add('')
$lines.Add('## 범위')
$lines.Add($scopes[$Role])
$lines.Add('')
$lines.Add('## 지시')
$lines.Add($directives[$Role])
$lines.Add('')
$lines.Add('## DoD')
$lines.Add("- docs/harness/todo.md 의 $Ticket DoD 충족")
$lines.Add('- PR 직전: validate-harness -Pr + run-eval')
if ($Role -eq 'Contract') { $lines.Add('- 산출: handoff-schema.md 형식 핸드오프') }
if ($Role -eq 'QA') { $lines.Add('- summarize-eval 출력을 PR ## 검증 계획에 붙여넣기') }
$lines.Add('')
$lines.Add('## 참조')
$lines.Add('- AGENTS.md · playbook.md (필요 섹션만)')
$lines.Add('- sample: docs/harness/examples/sample-ticket-code.md')

$lines | ForEach-Object { Write-Output $_ }
