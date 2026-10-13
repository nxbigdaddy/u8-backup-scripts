$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_status.txt'
$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()
$cmd=$c.CreateCommand()
$cmd.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%' OR command LIKE '%RESTORE%'"
$r=$cmd.ExecuteReader()
$o=''
while($r.Read()){
    $o+=('Session:'+$r[0]+' Cmd:'+$r[1]+' Status:'+$r[2]+' Pct:'+$r[3])+"`n"
}
$r.Close()
if($o -eq ''){$o='No active backup/restore'}
$c.Close()
$o | Out-File -FilePath $log -Encoding UTF8
Write-Output 'OK'
