$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form=New-Object Windows.Forms.Form
$form.Text="Project Vorticity - WRF Workstation";$form.Size=New-Object Drawing.Size(760,560);$form.StartPosition="CenterScreen"
$head=New-Object Windows.Forms.Label;$head.Text="PROJECT VORTICITY";$head.Font=New-Object Drawing.Font("Segoe UI",18,[Drawing.FontStyle]::Bold);$head.Location=New-Object Drawing.Point(20,16);$head.AutoSize=$true;$form.Controls.Add($head)
$combo=New-Object Windows.Forms.ComboBox;$combo.Location=New-Object Drawing.Point(22,70);$combo.Size=New-Object Drawing.Size(360,28);$combo.DropDownStyle="DropDownList";$form.Controls.Add($combo)
$scan=New-Object Windows.Forms.Button;$scan.Text="Scan computer";$scan.Location=New-Object Drawing.Point(400,68);$scan.Size=New-Object Drawing.Size(150,32);$form.Controls.Add($scan)
$setup=New-Object Windows.Forms.Button;$setup.Text="Install dependencies and sources";$setup.Location=New-Object Drawing.Point(22,115);$setup.Size=New-Object Drawing.Size(260,40);$form.Controls.Add($setup)
$log=New-Object Windows.Forms.TextBox;$log.Location=New-Object Drawing.Point(22,170);$log.Size=New-Object Drawing.Size(690,320);$log.Multiline=$true;$log.ScrollBars="Vertical";$log.ReadOnly=$true;$log.Anchor="Top,Bottom,Left,Right";$form.Controls.Add($log)
$status=New-Object Windows.Forms.Label;$status.Text="Choose an installed Ubuntu distribution.";$status.Location=New-Object Drawing.Point(22,505);$status.AutoSize=$true;$status.Anchor="Bottom,Left";$form.Controls.Add($status)
function Say([string]$s){$log.AppendText($s+[Environment]::NewLine)}
function Scan-Distros{$combo.Items.Clear();$lines=& wsl.exe --list --quiet 2>$null;foreach($line in $lines){$n=($line -replace [char]0,"").Trim();if($n){[void]$combo.Items.Add($n)}};if($combo.Items.Count -gt 0){$combo.SelectedIndex=0;Say "Found $($combo.Items.Count) WSL distribution(s)."}else{Say "No WSL distro found. Install Ubuntu from Microsoft Store first."}}
$scan.Add_Click({Scan-Distros;if($combo.SelectedItem){$d=[string]$combo.SelectedItem;$result=& wsl.exe -d $d -- bash -lc "cat /etc/os-release | head -n 3; command -v gcc; command -v gfortran; command -v nf-config; df -h ~ | tail -n 1" 2>&1;foreach($line in $result){Say ([string]$line)}}})
$setup.Add_Click({
 if(-not $combo.SelectedItem){[Windows.Forms.MessageBox]::Show("Install Ubuntu from Microsoft Store, then click Scan computer.")|Out-Null;return}
 $folder=$PSScriptRoot -replace '\\','/';$d=[string]$combo.SelectedItem;$mapped=& wsl.exe -d $d -- wslpath -a "$folder" 2>$null
 if(-not $mapped){Say "Cannot access extracted folder from WSL.";return}
 $linux=$mapped.Trim();$setup.Enabled=$false;$scan.Enabled=$false;$status.Text="Setup running. Logs will appear below.";Say "Starting setup in $d ..."
 $psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName="wsl.exe";$psi.Arguments='-d "'+$d+'" -- bash -lc "cd '+$linux+' && chmod +x scripts/*.sh && PV_ASSUME_YES=1 ./scripts/install.sh"';$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $script:proc=New-Object Diagnostics.Process;$script:proc.StartInfo=$psi;$script:proc.EnableRaisingEvents=$true
 $script:proc.add_OutputDataReceived({if($EventArgs.Data){$form.BeginInvoke([Action]{Say $EventArgs.Data})|Out-Null}})
 $script:proc.add_ErrorDataReceived({if($EventArgs.Data){$form.BeginInvoke([Action]{Say $EventArgs.Data})|Out-Null}})
 $script:proc.add_Exited({$code=$script:proc.ExitCode;$form.BeginInvoke([Action]{$setup.Enabled=$true;$scan.Enabled=$true;$status.Text="Finished (exit code $code)."})|Out-Null})
 [void]$script:proc.Start();$script:proc.BeginOutputReadLine();$script:proc.BeginErrorReadLine()
})
Scan-Distros
[void]$form.ShowDialog()
