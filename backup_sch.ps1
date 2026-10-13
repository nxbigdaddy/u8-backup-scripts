$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_sch.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Create a scheduled task on Windows (runs independently of SQL connection)
$taskCmd = 'cmd /c "sqlcmd -S . -U sa -P YOUR_DB_PASSWORD -Q \"BACKUP DATABASE [UFDATA_001_2020] TO DISK = N''C:\Backup\UFDATA_001_2020_FULL.bak'' WITH COMPRESSION, INIT, STATS = 10\" > C:\Backup\bk_log.txt 2>&1"'

# Use schtasks via xp_cmdshell
$schCmd = "schtasks /create /tn U8_Backup_Task /tr `"$taskCmd`" /sc once /st 00:00 /f"
$o+="Creating scheduled task..."

$cmd=$c.CreateCommand()
$cmd.CommandText="EXEC xp_cmdshell '$schCmd'"
$cmd.CommandTimeout=10
try{
    $r=$cmd.ExecuteReader()
    while($r.Read()){$v=$r[0];if($v-and$v.ToString().Trim()-ne''){$o+=('  '+$v.ToString().Trim())}}
    $r.Close()
}catch{$o+=('Sch err: '+$_.Exception.Message)}

# Run the task now
$o+=''
$o+="Running task at $(Get-Date)"
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell 'schtasks /run /tn U8_Backup_Task'"
$cmd2.CommandTimeout=10
try{
    $r2=$cmd2.ExecuteReader()
    while($r2.Read()){$v=$r2[0];if($v-and$v.ToString().Trim()-ne''){$o+=('  '+$v.ToString().Trim())}}
    $r2.Close()
    $o+='Task submitted!'
}catch{$o+=('Run err: '+$_.Exception.Message)}

# Verify
Start-Sleep -s 5
$cmd3=$c.CreateCommand()
$cmd3.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r3=$cmd3.ExecuteReader()
$found=0
while($r3.Read()){
    $found=1
    $o+=('BACKUP: Sess:{0} Status:{1} Pct:{2}%' -f $r3[0],$r3[2],[Math]::Round([double]$r3[3],1))
}
$r3.Close()
if($found -eq 0){$o+='No backup session detected yet'}

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
