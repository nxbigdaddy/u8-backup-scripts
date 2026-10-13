$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\status_now.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Check backup sessions
$cmd=$c.CreateCommand()
$cmd.CommandText="SELECT session_id, command, status, percent_complete, DATEDIFF(SECOND,start_time,GETDATE())/60.0 AS elapsed_min FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r=$cmd.ExecuteReader()
$found=0
while($r.Read()){
    $found=1
    $o+=('Session:{0} Cmd:{1} Status:{2} Pct:{3}% Elapsed:{4}min' -f $r[0],$r[1],$r[2],[Math]::Round([double]$r[3],1),[Math]::Round([double]$r[4],1))
}
$r.Close()
if($found -eq 0){$o+='No active backup session'}

# Check file
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell 'dir C:\Backup\*.bak 2>&1'"
$r2=$cmd2.ExecuteReader()
$o+=''
$o+='Files in C:\Backup:'
while($r2.Read()){
    $line=$r2[0]
    if($line -and $line.ToString().Trim() -ne ''){
        $o+=('  '+$line.ToString().Trim())
    }
}
$r2.Close()

# Also check bk_output.txt
$cmd3=$c.CreateCommand()
$cmd3.CommandText="EXEC xp_cmdshell 'type C:\Backup\bk_output.txt 2>&1'"
$r3=$cmd3.ExecuteReader()
$o+=''
$o+='bk_output.txt:'
while($r3.Read()){
    $line=$r3[0]
    if($line -and $line.ToString().Trim() -ne ''){
        $o+=('  '+$line.ToString().Trim())
    }
}
$r3.Close()

# Check D:\Backup too
$cmd4=$c.CreateCommand()
$cmd4.CommandText="EXEC xp_cmdshell 'dir D:\Backup\*.bak 2>&1'"
$r4=$cmd4.ExecuteReader()
$o+=''
$o+='Files in D:\Backup:'
while($r4.Read()){
    $line=$r4[0]
    if($line -and $line.ToString().Trim() -ne ''){
        $o+=('  '+$line.ToString().Trim())
    }
}
$r4.Close()

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
