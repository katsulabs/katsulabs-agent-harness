# 쉘 환경 설정 (macOS / Windows)

Harness Runtime 스크립트는 **macOS·Linux·Git Bash**와 **PowerShell 7.4+** 둘 다 지원합니다.

## PowerShell 버전

| 항목 | 값 |
|------|-----|
| 최소 버전 | **7.4.0** |
| 권장 | 7.4 LTS 최신 패치 |
| 실행기 | `pwsh` (Windows PowerShell 5.1 `powershell` 아님) |

### 설치 / 버전 맞추기

**Windows (winget)**

```powershell
winget install --id Microsoft.PowerShell --source winget
winget upgrade --id Microsoft.PowerShell
```

**macOS (Homebrew)**

```bash
brew install powershell/tap/powershell
brew upgrade powershell
```

**Linux**

[Microsoft 설치 가이드](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) 참고.

### 확인

```powershell
pwsh scripts/check-shell.ps1
```

또는:

```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
```

`7.4.x` 이상이면 OK.

## Bash (macOS / Linux / Git Bash)

Git Bash(Windows) 또는 macOS 기본 bash로 `.sh` 스크립트를 직접 실행할 수 있습니다.

```bash
./scripts/check-shell.sh
```

## 명령 매핑

| 작업 | macOS / Linux / Git Bash | Windows (pwsh) |
|------|--------------------------|----------------|
| 하네스 검증 | `./scripts/validate-harness.sh` | `pwsh scripts/validate-harness.ps1` |
| PR 직전 | `./scripts/validate-harness.sh -Pr` | `pwsh scripts/validate-harness.ps1 -Pr` |
| eval | `./scripts/run-eval.sh` | `pwsh scripts/run-eval.ps1` |
| hooks 설치 | `./scripts/install-githooks.sh` | `pwsh scripts/install-githooks.ps1` |

## pre-commit

`.githooks/pre-commit`은 `pwsh`가 있으면 `.ps1`, 없으면 `.sh`를 실행합니다.  
Windows에서 Git Bash만 쓰는 경우에도 `.sh` 경로로 동작합니다.

## CI

GitHub Actions는 `validate`/`test`(ubuntu)와 OS별 `*-platforms` jobs로 양쪽 경로를 검증합니다 (`harness-gate.yml`).
