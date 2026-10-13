$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_final.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Check backup session
$cmd=$c.CreateCommand()
$cmd.CommandText="SELECT session_id, command, status, percent_complete, DATEDIFF(SECOND,start_time,GETDATE())/60 AS elapsed_min FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r=$cmd.ExecuteReader()
$found=0
while($r.Read()){
    $found=1
    $pct=[Math]::Round([double]$r[3],1)
    $o+="Session:{0} Cmd:{1} Status:{2} Pct:{3}% Elapsed:{4}min" -f $r[0],$r[1],$r[2],$pct,$r[4]
}
$r.Close()
if($found -eq 0){$o+='No active backup - it may have completed!'}

# Check file via xp_cmdshell
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell 'dir C:\Backup\*.bak'"
$r2=$cmd2.ExecuteReader()
$o+=''
$o+='File info:'
while($r2.Read()){
    $line=$r2[0]
    if($line -and $line.ToString().Trim() -ne ''){
        $o+=('  '+$line.ToString().Trim())
    }
}
$r2.Close()
$c.Close()

$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
