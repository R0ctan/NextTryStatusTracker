$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SharedValidateScript = "D:\Dev\LUA\_GitHub\shared-tools\validate-addon.ps1"

if (-not (Test-Path $SharedValidateScript)) {
    throw "Shared validate script not found: $SharedValidateScript"
}

& $SharedValidateScript `
    -RepoRoot $RepoRoot `
    -AddonName "NextTryStatusTracker"