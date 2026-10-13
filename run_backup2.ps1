$ErrorActionPreference='Continue'
$bkPath='D:\Backup\UFDATA_001_2020_FULL_20260626.bak'
$log='<workspace>\U8-T\backup_result.txt'
$o=@()

try{
    # Create backup dir
    $c=New-Object System.Data.SqlClient.SqlConnection
    $c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=0'
    $c.Open()
    $cmd=$c.CreateCommand()
    $cmd.CommandText="EXEC xp_cmdshell 'if not exist D:\Backup mkdir D:\Backup'"
    $cmd.ExecuteNonQuery() | Out-Null
    $c.Close()

    # Run backup
    $c2=New-Object System.Data.SqlClient.SqlConnection
    $c2.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=0'
    $c2.Open()

    $backupSQL="BACKUP DATABASE [UFDATA_001_2020] TO DISK = N'$bkPath' WITH COMPRESSION, INIT, STATS = 10"

    $sw=[System.Diagnostics.Stopwatch]::StartNew()
    $cmd2=$c2.CreateCommand()
    $cmd2.CommandText=$backupSQL
    $cmd2.CommandTimeout=7200

    $o+="Backup started at $(Get-Date)"
    $o+="Command: $backupSQL"
    try{
        $cmd2.ExecuteNonQuery()
        $sw.Stop()
        $o+="SUCCESS! Duration: $([Math]::Round($sw.Elapsed.TotalMinutes,1)) min"
    }catch{
        $sw.Stop()
        $o+="FAILED: $($_.Exception.Message)"
        $o+="Duration before fail: $([Math]::Round($sw.Elapsed.TotalMinutes,1)) min"
    }
    $c2.Close()

    # Check file
    $o+=''
    $o+='Checking file size...'
    $fi=Get-Item -Path $bkPath -ErrorAction SilentlyContinue
    if($fi){
        $sizeGB=[Math]::Round($fi.Length/1GB,2)
        $o+="File: $bkPath"
        $o+="Size: $sizeGB GB ($($fi.Length) bytes)"
    }else{
        $o+="File not found at $bkPath"
        # Try via xp_cmdshell
        $c3=New-Object System.Data.SqlClient.SqlConnection
        $c3.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
        $c3.Open()
        $cmd3=$c3.CreateCommand()
        $cmd3.CommandText="EXEC xp_cmdshell 'dir $bkPath'"
        $r=$cmd3.ExecuteReader()
        while($r.Read()){$line=$r[0];if($line){$o+=$line.Trim()}}
        $r.Close()
        $c3.Close()
    }
}catch{
    $o+='OUTER ERROR: '+$_.Exception.Message
}

$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
