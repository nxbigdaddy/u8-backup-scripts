$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_go.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

$o+="Time: $(Get-Date)"

# Make dir
$cmd0=$c.CreateCommand();$cmd0.CommandText="EXEC xp_cmdshell 'mkdir C:\Backup 2>nul'";$cmd0.ExecuteNonQuery()|Out-Null

# Start backup via sqlcmd - this runs in a SEPARATE process, immune to our disconnection
$bk="BACKUP DATABASE [UFDATA_001_2020] TO DISK=N'C:\Backup\UFDATA_001_2020_FULL_20260626.bak' WITH COMPRESSION,INIT,STATS=10"
$cmdStr="sqlcmd -S . -U sa -P YOUR_DB_PASSWORD -Q `"$bk`" -o C:\Backup\bk_log.txt"

$o+="Cmd: $cmdStr"

$cmd=$c.CreateCommand()
$cmd.CommandText="EXEC xp_cmdshell '$cmdStr'"
$cmd.CommandTimeout=30
try{
    $r=$cmd.ExecuteReader()
    while($r.Read()){$v=$r[0];if($v-and$v.ToString().Trim()-ne''){$o+=('> '+$v.ToString().Trim())}}
    $r.Close()
    $o+='sqlcmd launched'
}catch{$o+=('ERR: '+$_.Exception.Message)}

# Quick verify
Start-Sleep -s 5
$cmd3=$c.CreateCommand()
$cmd3.CommandText="SELECT session_id,status,percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r3=$cmd3.ExecuteReader()
while($r3.Read()){$o+=('BACKUP: Sess:{0} {1} {2}%' -f $r3[0],$r3[2],[Math]::Round([double]$r3[3],1))}
$r3.Close()

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
