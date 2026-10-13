$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_detached.txt'
$o=@()

# Step 1: Write batch file content
$batContent = @'
@echo off
echo Backup started at %date% %time% > C:\Backup\bk_log.txt
sqlcmd -S . -U sa -P YOUR_DB_PASSWORD -Q "BACKUP DATABASE [UFDATA_001_2020] TO DISK = N'C:\Backup\UFDATA_001_2020_FULL.bak' WITH COMPRESSION, INIT, STATS = 10" >> C:\Backup\bk_log.txt 2>&1
echo Exit code: %ERRORLEVEL% >> C:\Backup\bk_log.txt
echo Backup finished at %date% %time% >> C:\Backup\bk_log.txt
'@

# Base64 encode
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($batContent))
$o+="Batch base64: $($b64.Substring(0,50))..."

# Connect to SQL
$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Step 2: Write batch file on server via xp_cmdshell PowerShell
$pwshCmd = "powershell -NoProfile -Command `"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('$b64')) | Out-File -FilePath C:\Backup\bk_go.bat -Encoding ASCII`""

$o+='Deploying batch file...'
$cmd=$c.CreateCommand()
$cmd.CommandText="EXEC xp_cmdshell '$pwshCmd'"
$cmd.CommandTimeout=10
try{$cmd.ExecuteNonQuery()|Out-Null;$o+='Batch deployed'}catch{$o+=('Deploy err: '+$_.Exception.Message)}

# Step 3: Launch the batch file with START /B (fully detached)
$o+=''
$o+="Launching detached backup at $(Get-Date)"
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell 'start /B cmd /c C:\Backup\bk_go.bat'"
$cmd2.CommandTimeout=10
try{$cmd2.ExecuteNonQuery()|Out-Null;$o+='Detached process launched!'}catch{$o+=('Launch err: '+$_.Exception.Message)}

# Step 4: Quick verify
Start-Sleep -s 5
$cmd3=$c.CreateCommand()
$cmd3.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r=$cmd3.ExecuteReader()
$found=0
while($r.Read()){
    $found=1
    $o+=('BACKUP: Sess:{0} Status:{1} Pct:{2}%' -f $r[0],$r[2],[Math]::Round([double]$r[3],1))
}
$r.Close()
if($found -eq 0){$o+='No session yet (or already completed)'}

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
