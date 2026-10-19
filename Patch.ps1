param(
 [Parameter(Mandatory=$true)][ValidateSet('startup','trial1','trial2','trial3','zbyszek-combined')][string[]]$Patch,
 [ValidateSet('Validate','Apply','Restore')][string]$Action='Validate',
 [Parameter(Mandatory=$true)][string]$GameFolder
)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'Engine.ps1') -Patch $Patch -Action $Action -GameFolder $GameFolder
