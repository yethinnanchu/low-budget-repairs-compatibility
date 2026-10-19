#requires -Version 5.1
param([switch]$NoLaunch)
# Online bootstrap. Review this file or use the offline ZIP instead.
$ErrorActionPreference='Stop'
$releaseVersion='v0.2.0'
$zipName='LBR-Compatibility-v0.2.0.zip'
$expected='f912fb16614e4315fcdc21929eec4dda5fc55c432d66f2d3ed6e91cb41432ad3'
$url='https://github.com/yethinnanchu/low-budget-repairs-compatibility/releases/download/'+$releaseVersion+'/'+$zipName
[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$base=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'LowBudgetRepairsCompatibility'
$staging=Join-Path $base ('downloads\'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging -Force | Out-Null
$zip=Join-Path $staging $zipName
Write-Host 'Downloading experimental compatibility tool v0.2.0...'
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
if((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected){throw 'Release checksum mismatch. Nothing was launched.'}
$extracted=Join-Path $staging 'package'
Expand-Archive -LiteralPath $zip -DestinationPath $extracted
$install=Join-Path $base $releaseVersion
if(Test-Path -LiteralPath $install){
 foreach($file in Get-ChildItem -LiteralPath $extracted -File){
  $existing=Join-Path $install $file.Name
  if(!(Test-Path -LiteralPath $existing) -or (Get-FileHash -LiteralPath $existing).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){
   throw "Existing installation differs: $existing. Keep its backups and use a fresh offline ZIP folder."
  }
 }
}else{Move-Item -LiteralPath $extracted -Destination $install}
Write-Host ('Verified. Opening interface from '+$install)
Write-Host 'Select your game folder and use Validate first. No patches are applied automatically.'
$shell=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
if($NoLaunch){Write-Output 'Release download, SHA256 and extraction verified; UI launch skipped.';return}
Start-Process -FilePath $shell -ArgumentList ('-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "'+(Join-Path $install 'UI.ps1')+'"')
