$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_one_shot.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

$o+="Time: $(Get-Date)"

# Build command carefully
# T-SQL: '' inside string = literal '
# CMD: doesn't care about single quotes
# Result: sqlcmd gets: BACKUP... N'C:\Backup\...bak' WITH...
$tsqlCmd = "EXEC xp_cmdshell 'start /B sqlcmd -S . -U sa -P YOUR_DB_PASSWORD -Q `"BACKUP DATABASE [UFDATA_001_2020] TO DISK = N''C:\Backup\UFDATA_001_2020_FULL.bak'' WITH COMPRESSION, INIT`" -o C:\Backup\bk_log.txt'"

$o+=''
$o+='T-SQL command:'
$o+=($tsqlCmd.Substring(0,[Math]::Min(200,$tsqlCmd.Length))+'...')

$cmd=$c.CreateCommand()
$cmd.CommandText=$tsqlCmd
$cmd.CommandTimeout=10
try{
    $r=$cmd.ExecuteReader()
    while($r.Read()){$v=$r[0];if($v-and$v.ToString().Trim()-ne''){$o+=('xp: '+$v.ToString().Trim())}}
    $r.Close()
    $o+='Launched!'
}catch{$o+=('ERR: '+$_.Exception.Message)}

# Verify
Start-Sleep -s 5
$cmd2=$c.CreateCommand()
$cmd2.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r2=$cmd2.ExecuteReader()
$found=0
while($r2.Read()){
    $found=1
    $o+=('BACKUP: Sess:{0} Status:{1} Pct:{2}%' -f $r2[0],$r2[2],[Math]::Round([double]$r2[3],1))
}
$r2.Close()
if($found -eq 0){$o+='No backup session yet'}
else{$o+='BACKUP IS RUNNING!'}

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
