$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SharedBuildScript = "D:\Dev\LUA\_GitHub\shared-tools\build-addon.ps1"

if (-not (Test-Path $SharedBuildScript)) {
    throw "Shared build script not found: $SharedBuildScript"
}

& $SharedBuildScript `
    -RepoRoot $RepoRoot `
    -AddonName "NextTryStatusTracker"