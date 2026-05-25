$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$SharedDeployScript = "D:\Dev\LUA\_GitHub\shared-tools\deploy-addon.ps1"

& $SharedDeployScript `
    -RepoRoot $RepoRoot `
    -AddonName "NextTryStatusTracker"