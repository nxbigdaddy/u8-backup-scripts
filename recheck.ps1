$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\recheck.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

function RunXP($cmd){
    $cmd2=$c.CreateCommand()
    $cmd2.CommandText="EXEC xp_cmdshell '$cmd'"
    $r=$cmd2.ExecuteReader()
    $rows=@()
    while($r.Read()){
        $v=$r[0]
        if($v -and $v.ToString().Trim() -ne ''){$rows+=$v.ToString().Trim()}
    }
    $r.Close()
    return $rows -join "`n"
}

$o+='=== All Drives with Free Space ==='
$o+=(RunXP 'wmic logicaldisk get name,size,freespace /format:list')

$o+=''
$o+='=== C:\Backup dir ==='
$o+=(RunXP 'dir C:\Backup\*.bak 2>&1')

$o+=''
$o+='=== D:\Backup dir ==='
$o+=(RunXP 'dir D:\Backup\*.bak 2>&1')

$o+=''
$o+='=== Active Backup Sessions ==='
$cmd=$c.CreateCommand()
$cmd.CommandText="SELECT session_id, command, status, percent_complete, estimated_completion_time FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r=$cmd.ExecuteReader()
while($r.Read()){
    $eta=$r[4]
    if($eta -eq 0){$eta='N/A'}
    $o+=('Session:{0} Cmd:{1} Status:{2} Pct:{3}% ETA(sec):{4}' -f $r[0],$r[1],$r[2],[Math]::Round([double]$r[3],1),$eta)
}
$r.Close()

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output 'OK'
