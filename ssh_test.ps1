$ErrorActionPreference='Stop'
$out='<workspace>\U8-T\ssh_test.txt'

# Try SSH with password via .NET Process
$proc = New-Object System.Diagnostics.Process
$proc.StartInfo.FileName = 'ssh'
$proc.StartInfo.Arguments = '-o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL root@203.0.113.10 "df -h / | tail -3; echo ---; docker ps 2>/dev/null || systemctl status mssql-server 2>/dev/null | head -3"'
$proc.StartInfo.UseShellExecute = $false
$proc.StartInfo.RedirectStandardInput = $true
$proc.StartInfo.RedirectStandardOutput = $true
$proc.StartInfo.RedirectStandardError = $true
$proc.StartInfo.CreateNoWindow = $true

$proc.Start() | Out-Null

# Send password via stdin
$proc.StandardInput.WriteLine('YOUR_PASSWORD')
$proc.StandardInput.Close()

$stdout = $proc.StandardOutput.ReadToEnd()
$stderr = $proc.StandardError.ReadToEnd()
$proc.WaitForExit(15000)

Write-Output "EXIT: $($proc.ExitCode)"
Write-Output "STDOUT: $stdout"
Write-Output "STDERR: $stderr"

$stdout + "`n" + $stderr | Out-File -FilePath $out -Encoding UTF8
Write-Output 'DONE'
