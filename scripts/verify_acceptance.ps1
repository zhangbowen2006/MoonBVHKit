param(
  [string]$MoonPath = "moon"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Invoke-Moon {
  param([string[]]$Arguments)

  & $MoonPath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "moon $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
  }
}

Write-Host "[1/10] Toolchain"
Invoke-Moon @("version", "--all")

Write-Host "[2/10] Strict check"
Invoke-Moon @("check", "--deny-warn")

Write-Host "[3/10] Build"
Invoke-Moon @("build")

Write-Host "[4/10] Strict tests"
Invoke-Moon @("test", "--deny-warn")

Write-Host "[5/10] Formatting"
Invoke-Moon @("fmt", "--check")

Write-Host "[6/10] Public API snapshot"
Invoke-Moon @("info")
git diff --exit-code -- "*.mbti"
if ($LASTEXITCODE -ne 0) {
  throw "moon info changed a tracked public API snapshot"
}

Write-Host "[7/10] CLI text report"
Invoke-Moon @("run", "cmd/main")

Write-Host "[8/10] CLI JSON quality report"
Invoke-Moon @("run", "cmd/main", "--", "--quality", "--json")

Write-Host "[9/10] CLI CSV profile matrix"
Invoke-Moon @("run", "cmd/main", "--", "--profiles", "--csv")

Write-Host "[10/10] Basic example"
Invoke-Moon @("run", "examples/basic")

Write-Host "MoonBVHKit acceptance verification passed."
