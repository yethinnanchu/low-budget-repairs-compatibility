param(
 [Parameter(Mandatory=$true)][ValidateSet('startup','trial1','trial2','trial3')][string]$Patch,
 [ValidateSet('Validate','Apply','Restore')][string]$Action='Validate',
 [Parameter(Mandatory=$true)][string]$GameFolder
)
$ErrorActionPreference='Stop'
$m=Get-Content -LiteralPath (Join-Path $PSScriptRoot ($Patch+'.json')) -Raw | ConvertFrom-Json
$target=Join-Path $GameFolder $m.file
function HashBytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
$bytes=[IO.File]::ReadAllBytes($target)
$current=HashBytes $bytes
if($current -notin @($m.original_sha256,$m.trial_sha256)){throw 'Unknown file hash: this patch is only for the exact documented build/state.'}
$restore=$Action -eq 'Restore'
if(($restore -and $current -eq $m.original_sha256) -or (!$restore -and $current -eq $m.trial_sha256)){Write-Output 'Already in requested state; no files changed.';return}
foreach($c in $m.changes){
 $expected=if($restore){$c.trial}else{$c.original}
 $replacement=if($restore){$c.original}else{$c.trial}
 if($c.offset -lt 0 -or $c.offset -ge $bytes.Length -or $bytes[$c.offset] -ne $expected){throw 'Expected byte mismatch.'}
 $bytes[$c.offset]=[byte]$replacement
}
$expectedHash=if($restore){$m.original_sha256}else{$m.trial_sha256}
if((HashBytes $bytes) -ne $expectedHash){throw 'Computed output hash mismatch.'}
if($Action -eq 'Validate'){Write-Output "$Patch validated in memory; installed files unchanged.";return}
if(Get-Process LowBudgetRepairs -ErrorAction SilentlyContinue){throw 'Close the game before applying/restoring.'}
if(!$restore){
 $backupDir=Join-Path $PSScriptRoot 'backups'
 New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
 $backup=Join-Path $backupDir ($m.original_sha256+'.original')
 if(Test-Path -LiteralPath $backup){if((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant() -ne $m.original_sha256){throw 'Existing backup mismatch.'}}
 else{Copy-Item -LiteralPath $target -Destination $backup}
}
[IO.File]::WriteAllBytes($target,$bytes)
if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash){throw 'Installed hash verification failed; restore from backup.'}
Write-Output "$Patch $Action completed and verified."
