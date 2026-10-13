$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\block_check.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

$cmd=$c.CreateCommand()
$cmd.CommandText=@"
SELECT 
    r.session_id,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time,
    r.wait_resource,
    r.command,
    r.status,
    r.percent_complete,
    t.text AS sql_text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id = 2138
"@
$r=$cmd.ExecuteReader()
while($r.Read()){
    for($i=0;$i-lt$r.FieldCount;$i++){
        $n=$r.GetName($i)
        $v=$r.GetValue($i)
        if($v -eq $null -or $v -eq [DBNull]::Value){$v='NULL'}
        $o+=('{0}: {1}' -f $n,$v.ToString().Substring(0,[Math]::Min(200,$v.ToString().Length)))
    }
}
$r.Close()
$c.Close()

$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output 'OK'
