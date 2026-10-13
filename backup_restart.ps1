$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_restart.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=0'
$c.Open()

# Kill old backup
$o+='Killing old backup session...'
$cmd=$c.CreateCommand()
$cmd.CommandText="KILL 851"
try{$cmd.ExecuteNonQuery();$o+='Killed.'}catch{$o+=('Kill err: '+$_.Exception.Message)}

Start-Sleep -Seconds 2

# Create C:\Backup
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell 'if not exist C:\Backup mkdir C:\Backup'"
$cmd2.ExecuteNonQuery() | Out-Null

# Start new backup to C:
$bkPath='C:\Backup\UFDATA_001_2020_FULL_20260626.bak'
$o+=''
$o+="Starting backup to $bkPath"
$o+="Time: $(Get-Date)"

$cmd3=$c.CreateCommand()
$cmd3.CommandText="BACKUP DATABASE [UFDATA_001_2020] TO DISK = N'$bkPath' WITH COMPRESSION, INIT, STATS = 10"
$cmd3.CommandTimeout=7200

$sw=[System.Diagnostics.Stopwatch]::StartNew()
try{
    $cmd3.ExecuteNonQuery()
    $sw.Stop()
    $o+="SUCCESS! Duration: $([Math]::Round($sw.Elapsed.TotalMinutes,1)) min"
}catch{
    $sw.Stop()
    $o+="FAILED after $([Math]::Round($sw.Elapsed.TotalMinutes,1)) min: $($_.Exception.Message)"
}

# Check result
$o+=''
$cmd4=$c.CreateCommand()
$cmd4.CommandText="EXEC xp_cmdshell 'dir C:\Backup\*.bak'"
$r=$cmd4.ExecuteReader()
while($r.Read()){$line=$r[0];if($line){$o+=$line.Trim()}}
$r.Close()

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
