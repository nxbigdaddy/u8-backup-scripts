$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_v3.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Make sure C:\Backup exists
$cmd=$c.CreateCommand()
$cmd.CommandText="EXEC xp_cmdshell 'if not exist C:\Backup mkdir C:\Backup'"
$cmd.ExecuteNonQuery() | Out-Null

# Set the backup to run with a long timeout but don't wait
$bkPath='C:\Backup\UFDATA_001_2020_FULL_20260626.bak'
$o+="Starting backup to: $bkPath"
$o+="Start time: $(Get-Date)"

$cmd2=$c.CreateCommand()
$cmd2.CommandText="BACKUP DATABASE [UFDATA_001_2020] TO DISK = N'$bkPath' WITH COMPRESSION, INIT, STATS = 10"
$cmd2.CommandTimeout=0  # No timeout - wait forever

try{
    $cmd2.ExecuteNonQuery()
    $o+="COMPLETED at $(Get-Date)"
}catch{
    $o+="ERROR: $($_.Exception.Message)"
}

# Check result
$o+=''
$cmd3=$c.CreateCommand()
$cmd3.CommandText="EXEC xp_cmdshell 'dir C:\Backup\*.bak'"
$r=$cmd3.ExecuteReader()
while($r.Read()){
    $line=$r[0]
    if($line -and $line.ToString().Trim() -ne ''){$o+=('  '+$line.ToString().Trim())}
}
$r.Close()
$c.Close()

$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
