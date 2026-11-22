$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "Project Vorticity - WRF Workstation"
$form.Size = New-Object Drawing.Size(820,640)
$form.MinimumSize = New-Object Drawing.Size(760,580)
$form.StartPosition = "CenterScreen"

$head = New-Object Windows.Forms.Label
$head.Text = "PROJECT VORTICITY"
$head.Font = New-Object Drawing.Font("Segoe UI",18,[Drawing.FontStyle]::Bold)
$head.Location = New-Object Drawing.Point(20,16)
$head.AutoSize = $true
$form.Controls.Add($head)

$intro = New-Object Windows.Forms.Label
$intro.Text = "WRF / WPS setup for Ubuntu on WSL2"
$intro.Location = New-Object Drawing.Point(22,50)
$intro.AutoSize = $true
$form.Controls.Add($intro)

$combo = New-Object Windows.Forms.ComboBox
$combo.Location = New-Object Drawing.Point(22,82)
$combo.Size = New-Object Drawing.Size(420,28)
$combo.DropDownStyle = "DropDownList"
$form.Controls.Add($combo)

$scan = New-Object Windows.Forms.Button
$scan.Text = "Scan computer"
$scan.Location = New-Object Drawing.Point(460,80)
$scan.Size = New-Object Drawing.Size(145,32)
$form.Controls.Add($scan)

$setup = New-Object Windows.Forms.Button
$setup.Text = "1. Install dependencies + sources"
$setup.Location = New-Object Drawing.Point(22,126)
$setup.Size = New-Object Drawing.Size(280,42)
$form.Controls.Add($setup)

$build = New-Object Windows.Forms.Button
$build.Text = "2. Build WRF + WPS"
$build.Location = New-Object Drawing.Point(316,126)
$build.Size = New-Object Drawing.Size(220,42)
$form.Controls.Add($build)

$log = New-Object Windows.Forms.TextBox
$log.Location = New-Object Drawing.Point(22,184)
$log.Size = New-Object Drawing.Size(760,385)
$log.Multiline = $true
$log.ScrollBars = "Vertical"
$log.ReadOnly = $true
$log.WordWrap = $false
$log.Font = New-Object Drawing.Font("Consolas",9)
$log.Anchor = "Top,Bottom,Left,Right"
$form.Controls.Add($log)

$status = New-Object Windows.Forms.Label
$status.Text = "Choose an installed Ubuntu distribution."
$status.Location = New-Object Drawing.Point(22,582)
$status.AutoSize = $true
$status.Anchor = "Bottom,Left"
$form.Controls.Add($status)

function Say([string]$s) {
    if ($log.IsDisposed) { return }
    $log.AppendText($s + [Environment]::NewLine)
}

function Bash-Quote([string]$s) {
    return "'" + $s.Replace("'","'\''") + "'"
}

function Start-WslTask([string]$distro, [string]$command, [bool]$asRoot, [scriptblock]$onComplete) {
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($command))
    $args = '-d "' + $distro + '" '
    if ($asRoot) { $args += '-u root ' }
    $args += '-- bash -lc "echo ' + $encoded + ' | base64 -d | bash"'

    $p = New-Object Diagnostics.Process
    $p.StartInfo = New-Object Diagnostics.ProcessStartInfo
    $p.StartInfo.FileName = "wsl.exe"
    $p.StartInfo.Arguments = $args
    $p.StartInfo.UseShellExecute = $false
    $p.StartInfo.RedirectStandardOutput = $true
    $p.StartInfo.RedirectStandardError = $true
    $p.EnableRaisingEvents = $true

    $outHandler = {
        param($sender,$e)
        if ($e.Data) {
            $line = $e.Data
            $ui = { Say $line }.GetNewClosure()
            $form.BeginInvoke([Action]$ui) | Out-Null
        }
    }.GetNewClosure()
    $errHandler = {
        param($sender,$e)
        if ($e.Data) {
            $line = $e.Data
            $ui = { Say $line }.GetNewClosure()
            $form.BeginInvoke([Action]$ui) | Out-Null
        }
    }.GetNewClosure()
    $exitHandler = {
        $exitCode = $p.ExitCode
        $ui = {
            if ($onComplete) { & $onComplete $exitCode }
            else {
                $setup.Enabled = $true
                $build.Enabled = $true
                $scan.Enabled = $true
                $status.Text = "Finished (exit code $exitCode)."
            }
        }.GetNewClosure()
        $form.BeginInvoke([Action]$ui) | Out-Null
    }.GetNewClosure()

    $p.add_OutputDataReceived($outHandler)
    $p.add_ErrorDataReceived($errHandler)
    $p.add_Exited($exitHandler)
    $script:activeProcess = $p
    [void]$p.Start()
    $p.BeginOutputReadLine()
    $p.BeginErrorReadLine()
}

function Scan-Distros {
    $combo.Items.Clear()
    $lines = & wsl.exe --list --quiet 2>$null
    foreach ($line in $lines) {
        $name = ($line -replace [char]0,"").Trim()
        if ($name) { [void]$combo.Items.Add($name) }
    }
    if ($combo.Items.Count -gt 0) {
        $combo.SelectedIndex = 0
        Say "Found $($combo.Items.Count) WSL distribution(s)."
    } else {
        Say "No WSL distribution found. Install Ubuntu from Microsoft Store, then scan again."
    }
}

$scan.Add_Click({
    Scan-Distros
    if ($combo.SelectedItem) {
        $d = [string]$combo.SelectedItem
        $result = & wsl.exe -d $d -- bash -lc "cat /etc/os-release | head -n 3; echo '--- compilers ---'; command -v gcc; command -v gfortran; command -v mpif90; command -v nf-config; echo '--- disk ---'; df -h ~ | tail -n 1" 2>&1
        foreach ($line in $result) { Say ([string]$line) }
    }
})

$setup.Add_Click({
    if (-not $combo.SelectedItem) {
        [Windows.Forms.MessageBox]::Show("Install Ubuntu from Microsoft Store, then click Scan computer.") | Out-Null
        return
    }
    $d = [string]$combo.SelectedItem
    $repoFolder = Split-Path -Parent $PSScriptRoot
    $mapped = & wsl.exe -d $d -- wslpath -a "$repoFolder" 2>$null
    if (-not $mapped) { Say "Cannot access the extracted Project Vorticity folder from WSL."; return }
    $linux = $mapped.Trim()
    $linuxQ = Bash-Quote $linux

    $setup.Enabled = $false
    $build.Enabled = $false
    $scan.Enabled = $false
    $status.Text = "Installing Linux build dependencies..."
    Say "Installing compiler, MPI, NetCDF and WPS build dependencies as WSL root..."

    $scanCommand = "cd $linuxQ && chmod +x scripts/*.sh && ./scripts/status.sh"
    $depsCommand = "bash $linuxQ/scripts/install-dependencies.sh"
    $afterDeps = {
        param($code)
        if ($code -ne 0) {
            Say "Dependency installation failed. See the log above."
            $status.Text = "Dependency installation failed (exit code $code)."
            $setup.Enabled = $true; $build.Enabled = $true; $scan.Enabled = $true
            return
        }
        Say "Dependencies installed. Checking for existing WRF/WPS and obtaining missing source code..."
        $sourceCommand = "cd $linuxQ && PV_ASSUME_YES=1 PV_INSTALL_DEPS=false ./scripts/install.sh"
        $afterSources = {
            param($sourceCode)
            $setup.Enabled = $true; $build.Enabled = $true; $scan.Enabled = $true
            $status.Text = "Source setup finished (exit code $sourceCode)."
            if ($sourceCode -eq 0) { Say "Ready for step 2: Build WRF + WPS." }
            else { Say "Source setup failed. See the log above." }
        }.GetNewClosure()
        Start-WslTask $d $sourceCommand $false $afterSources
    }.GetNewClosure()
    $afterScan = {
        param($scanCode)
        if ($scanCode -ne 0) {
            Say "The initial status scan returned an error; continuing with dependency setup."
        }
        Say "Initial scan complete. Installing any missing build packages..."
        Start-WslTask $d $depsCommand $true $afterDeps
    }.GetNewClosure()
    Start-WslTask $d $scanCommand $false $afterScan
})

$build.Add_Click({
    if (-not $combo.SelectedItem) {
        [Windows.Forms.MessageBox]::Show("Select an installed Ubuntu distribution first.") | Out-Null
        return
    }
    $d = [string]$combo.SelectedItem
    $repoFolder = Split-Path -Parent $PSScriptRoot
    $mapped = & wsl.exe -d $d -- wslpath -a "$repoFolder" 2>$null
    if (-not $mapped) { Say "Cannot access the extracted Project Vorticity folder from WSL."; return }
    $linuxQ = Bash-Quote $mapped.Trim()

    $setup.Enabled = $false; $build.Enabled = $false; $scan.Enabled = $false
    $status.Text = "Building WRF and WPS. This may take a long time..."
    Say "Starting automated GNU/OpenMPI WRF and WPS build. Keep this window open."
    $command = "cd $linuxQ && PV_JOBS=2 ./scripts/build-wrf-wps.sh"
    Start-WslTask $d $command $false $null
})

Scan-Distros
[void]$form.ShowDialog()
