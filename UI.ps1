#requires -Version 5.1
param([switch]$SelfTest,[string]$PreviewPath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$choices=@(
 @{Id='startup';Title='Startup shader-preload workaround';Details='Enabled gameplay on the tested UHD 620. Skips startup graphics-state preloading. Later apartment/device-loss crashes remain unresolved.'},
 @{Id='trial1';Title='Experimental: Zbyszek LOD crossfade off';Details='Keeps all character detail levels; disables transition blending. Not a confirmed freeze fix.'},
 @{Id='trial2';Title='Experimental: Zbyszek shadows off';Details='Disables shadow casting on the living character. Not a confirmed freeze fix.'},
 @{Id='trial3';Title='Experimental: Zbyszek hair / moustache off';Details='Temporarily removes hair and moustache renderers. User progressed using partial views; full-body freeze not established as fixed.'},
 @{Id='zbyszek-combined';Title='Experimental: hair + LOD crossfade off';Details='Combines hair/moustache removal with crossfade disabled. All LOD meshes remain. Gameplay untested. Overlapping checked options apply only once.'}
)
$form=New-Object System.Windows.Forms.Form
$form.Text='Low-Budget Repairs Compatibility | v0.2.0 experimental'
$form.ClientSize=New-Object System.Drawing.Size(760,670)
$form.StartPosition='CenterScreen'
$form.FormBorderStyle='FixedDialog'
$form.MaximizeBox=$false
$form.AutoScaleMode='Dpi'
$form.Font=New-Object System.Drawing.Font('Segoe UI',10)
function Label($text,$x,$y,$w,$h){$c=New-Object System.Windows.Forms.Label;$c.Text=$text;$c.SetBounds($x,$y,$w,$h);$form.Controls.Add($c);return $c}
$null=Label 'Low-Budget Repairs Compatibility' 24 18 710 30
$null=Label 'Exact v1.7.17 build only. Reversible workarounds; later crashes remain unresolved.' 24 54 710 40
$null=Label '1. Choose the folder containing LowBudgetRepairs.exe' 24 102 710 24
$folder=New-Object System.Windows.Forms.TextBox
$folder.SetBounds(24,132,590,28)
$form.Controls.Add($folder)
$browse=New-Object System.Windows.Forms.Button
$browse.Text='Browse...';$browse.SetBounds(628,130,108,32);$form.Controls.Add($browse)
$browse.Add_Click({
 $dialog=New-Object System.Windows.Forms.OpenFileDialog
 $dialog.Title='Select LowBudgetRepairs.exe';$dialog.Filter='Game executable|LowBudgetRepairs.exe'
 if($dialog.ShowDialog() -eq 'OK'){$folder.Text=[IO.Path]::GetDirectoryName($dialog.FileName)}
 $dialog.Dispose()
})
$null=Label '2. Check one or more workarounds; click a row to read its description' 24 182 710 24
$select=New-Object System.Windows.Forms.CheckedListBox
$select.CheckOnClick=$true;$select.SetBounds(24,212,712,135)
foreach($c in $choices){$null=$select.Items.Add($c.Title)}
$form.Controls.Add($select)
$details=Label '' 24 358 712 74
$select.Add_SelectedIndexChanged({$details.Text=$choices[$select.SelectedIndex].Details})
$select.SelectedIndex=0
$select.SetItemChecked(0,$true)
$null=Label '3. Apply adds checked options. Restore removes checked options; others stay.' 24 438 712 25
$log=New-Object System.Windows.Forms.TextBox
$log.Multiline=$true;$log.ReadOnly=$true;$log.ScrollBars='Vertical';$log.SetBounds(24,514,712,126)
$form.Controls.Add($log)
$script:buttons=@()
foreach($mode in @('Validate','Apply','Restore')){
 $button=New-Object System.Windows.Forms.Button
 $button.Text=$mode;$button.Tag=$mode;$button.SetBounds((24+($script:buttons.Count*170)),470,155,34)
 $button.Add_Click({
  $action=$this.Tag
  foreach($b in $script:buttons){$b.Enabled=$false}
  $form.UseWaitCursor=$true
  try{
   if(!(Test-Path -LiteralPath (Join-Path $folder.Text 'LowBudgetRepairs.exe'))){throw 'Select the game installation folder first.'}
   $ids=@($select.CheckedIndices | ForEach-Object {$choices[$_].Id})
   if(!$ids.Count){throw 'Check at least one workaround.'}
   $log.Text='Checking '+($ids -join ', ')+'...'
   $form.Refresh()
   $result=& (Join-Path $PSScriptRoot 'Patch.ps1') -Patch $ids -Action $action -GameFolder $folder.Text
   $log.Text=($result -join [Environment]::NewLine)+[Environment]::NewLine+'Original backups are kept in the backups folder beside this tool.'
  }catch{
   $log.Text=$_.Exception.Message+[Environment]::NewLine+'Only known complete combinations on the exact game build are accepted.'
  }finally{
   foreach($b in $script:buttons){$b.Enabled=$true};$form.UseWaitCursor=$false
  }
 })
 $script:buttons+=$button;$form.Controls.Add($button)
}
$log.Text='No changes are made until you choose Apply or Restore. Validate checks the selected file in memory.'
if($SelfTest){
 if($choices.Count -ne 5 -or $form.Controls.Count -lt 10){throw 'UI construction failed.'}
 foreach($c in $choices){if(!(Test-Path -LiteralPath (Join-Path $PSScriptRoot ($c.Id+'.json')))){throw 'Missing patch manifest.'}}
 if($PreviewPath){
  $form.CreateControl()
  $bitmap=New-Object System.Drawing.Bitmap($form.Width,$form.Height)
  $form.DrawToBitmap($bitmap,(New-Object System.Drawing.Rectangle(0,0,$form.Width,$form.Height)))
  foreach($control in $form.Controls){
   $null=$control.Handle
   $rect=New-Object System.Drawing.Rectangle(($control.Left+8),($control.Top+31),$control.Width,$control.Height)
   $control.DrawToBitmap($bitmap,$rect)
  }
  $bitmap.Save($PreviewPath,[System.Drawing.Imaging.ImageFormat]::Png);$bitmap.Dispose()
 }
 $form.Dispose();Write-Output 'UI constructed successfully; five manifests found.';return
}
try{$null=$form.ShowDialog()}finally{$form.Dispose()}
