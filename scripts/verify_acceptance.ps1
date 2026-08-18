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

Write-Host "[1/14] Toolchain"
Invoke-Moon @("version", "--all")

Write-Host "[2/14] Strict check"
Invoke-Moon @("check", "--deny-warn")

Write-Host "[3/14] Build"
Invoke-Moon @("build")

Write-Host "[4/14] Strict tests"
Invoke-Moon @("test", "--deny-warn")

Write-Host "[5/14] Formatting"
Invoke-Moon @("fmt", "--check")

Write-Host "[6/14] Public API snapshot"
Invoke-Moon @("info")
git diff --exit-code -- "*.mbti"
if ($LASTEXITCODE -ne 0) {
  throw "moon info changed a tracked public API snapshot"
}

Write-Host "[7/14] CLI text report"
Invoke-Moon @("run", "cmd/main")

Write-Host "[8/14] CLI JSON quality report"
Invoke-Moon @("run", "cmd/main", "--", "--quality", "--json")

Write-Host "[9/14] CLI CSV profile matrix"
Invoke-Moon @("run", "cmd/main", "--", "--profiles", "--csv")

Write-Host "[10/14] CLI root-motion bounds"
Invoke-Moon @("run", "cmd/main", "--", "--bounds", "--json")

Write-Host "[11/14] CLI motion resampling"
Invoke-Moon @("run", "cmd/main", "--", "--resample", "12")

Write-Host "[12/14] CLI batch import gate"
Invoke-Moon @("run", "cmd/main", "--", "--batch", "--profile", "strict-ci", "--csv")

Write-Host "[13/14] CLI JUnit quality report"
Invoke-Moon @("run", "cmd/main", "--", "--junit")

Write-Host "[14/14] Basic example"
Invoke-Moon @("run", "examples/basic")

Write-Host "MoonBVHKit acceptance verification passed."
