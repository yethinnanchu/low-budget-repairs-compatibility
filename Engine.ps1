#requires -Version 5.1
param([string[]]$Patch,[string]$Action,[string]$GameFolder)
$ErrorActionPreference='Stop'
function HashBytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
$all=@{}
foreach($id in @('startup','trial1','trial2','trial3','zbyszek-combined')){$all[$id]=Get-Content -LiteralPath (Join-Path $PSScriptRoot ($id+'.json')) -Raw | ConvertFrom-Json}
$plans=[System.Collections.Generic.List[object]]::new()
$selected=@($Patch | Select-Object -Unique)
foreach($group in @($selected | ForEach-Object {$all[$_]} | Group-Object file)){
 $file=$group.Name;$target=Join-Path $GameFolder $file
 $current=[IO.File]::ReadAllBytes($target);$baseline=[byte[]]$current.Clone()
 $known=@($all.Values | Where-Object {$_.file -eq $file})
 $offsets=@{}
 foreach($m in $known){foreach($c in $m.changes){
  if($offsets.ContainsKey([int]$c.offset)){
   $old=$offsets[[int]$c.offset]
   if($old.original -ne $c.original -or $old.trial -ne $c.trial){throw 'Conflicting patch definitions; no files changed.'}
  }else{$offsets[[int]$c.offset]=$c}
 }}
 foreach($c in $offsets.Values){
  if($c.offset -lt 0 -or $c.offset -ge $current.Length){throw 'Patch offset outside file; no files changed.'}
  if($current[$c.offset] -notin @($c.original,$c.trial)){throw 'Unknown byte state; no files changed.'}
  $baseline[$c.offset]=[byte]$c.original
 }
 $originalHash=$known[0].original_sha256
 if((HashBytes $baseline) -ne $originalHash){throw 'Unknown file/build or unrelated modifications; no files changed.'}
 # Reject incomplete/corrupt states; accept complete combinations of known options.
 $covered=@{}
 foreach($m in $known){
  $complete=$true
  foreach($c in $m.changes){if($current[$c.offset] -ne $c.trial){$complete=$false;break}}
  if($complete){foreach($c in $m.changes){$covered[[int]$c.offset]=$true}}
 }
 foreach($c in $offsets.Values){if($current[$c.offset] -ne $c.original -and !$covered.ContainsKey([int]$c.offset)){throw 'Incomplete patch state; no files changed.'}}
 $output=[byte[]]$current.Clone()
 foreach($m in $group.Group){
  $single=[byte[]]$baseline.Clone()
  foreach($c in $m.changes){$single[$c.offset]=[byte]$c.trial}
  if((HashBytes $single) -ne $m.trial_sha256){throw 'Manifest hash mismatch; no files changed.'}
  foreach($c in $m.changes){$output[$c.offset]=if($Action -eq 'Restore'){[byte]$c.original}else{[byte]$c.trial}}
 }
 $plans.Add([pscustomobject]@{Target=$target;Before=$current;BeforeHash=(HashBytes $current);Original=$baseline;OriginalHash=$originalHash;After=$output;AfterHash=(HashBytes $output)})
}
if($Action -eq 'Validate'){Write-Output ('Validated combination in memory: '+($selected -join ', ')+'. Installed files unchanged.');return}
if(Get-Process LowBudgetRepairs -ErrorAction SilentlyContinue){throw 'Close the game before applying/restoring.'}
$backupDir=Join-Path $PSScriptRoot 'backups'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
foreach($plan in $plans){
 $backup=Join-Path $backupDir ($plan.OriginalHash+'.original')
 if(Test-Path -LiteralPath $backup){if((Get-FileHash -LiteralPath $backup).Hash.ToLowerInvariant() -ne $plan.OriginalHash){throw 'Backup hash mismatch; no game files changed.'}}
 else{[IO.File]::WriteAllBytes($backup,$plan.Original)}
 if((Get-FileHash -LiteralPath $plan.Target).Hash.ToLowerInvariant() -ne $plan.BeforeHash){throw 'Game file changed during validation; no game files changed.'}
}
$written=[System.Collections.Generic.List[object]]::new()
try{
 foreach($plan in $plans){
  if($plan.BeforeHash -eq $plan.AfterHash){continue}
  $written.Add($plan)
  [IO.File]::WriteAllBytes($plan.Target,$plan.After)
  if((Get-FileHash -LiteralPath $plan.Target).Hash.ToLowerInvariant() -ne $plan.AfterHash){throw 'Installed hash verification failed.'}
 }
}catch{
 $failure=$_.Exception.Message
 foreach($plan in $written){[IO.File]::WriteAllBytes($plan.Target,$plan.Before);if((Get-FileHash -LiteralPath $plan.Target).Hash.ToLowerInvariant() -ne $plan.BeforeHash){throw 'Rollback verification failed. Restore the original from backups.'}}
 throw ($failure+' Previous game files restored.')
}
Write-Output (($selected -join ', ')+': '+$Action+' completed and verified. Unselected changes preserved.')
