$ErrorActionPreference='Stop'
$out='<workspace>\U8-T\migrate_step.ps1'

# Step 2: Backup from Windows
$bkPath='D:\Backup\UFDATA_001_2020_FULL_20260626.bak'
$log='<workspace>\U8-T\backup_progress.txt'

try{
    $c=New-Object System.Data.SqlClient.SqlConnection
    $c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
    $c.Open()
    Write-Output 'Connected to Win SQL. Starting backup...'

    # Check if D:\Backup exists
    $cmd=$c.CreateCommand()
    $cmd.CommandText="EXEC xp_cmdshell 'if not exist D:\Backup mkdir D:\Backup'"
    $cmd.ExecuteNonQuery() | Out-Null

    # Check free space on D:
    $cmd2=$c.CreateCommand()
    $cmd2.CommandText="EXEC xp_fileexist 'D:\Backup\'"
    $r=$cmd2.ExecuteReader()
    while($r.Read()){Write-Output ('Backup dir exists: '+$r[0])}
    $r.Close()

    $c2=New-Object System.Data.SqlClient.SqlConnection
    $c2.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=0'
    $c2.Open()

    $backupSQL=@"
BACKUP DATABASE [UFDATA_001_2020] 
TO DISK = N'$bkPath' 
WITH COMPRESSION, INIT, STATS = 5
"@

    $cmd3=$c2.CreateCommand()
    $cmd3.CommandText=$backupSQL
    $cmd3.CommandTimeout=7200  # 2 hours max

    # Register info message handler for progress
    $handler=[Microsoft.SqlServer.MessageInfoEventHandler]{
        param($sender,$e)
        if($e.Message -match 'percent'){
            Write-Output ('PROGRESS: '+$e.Message)
        }
    }

    try{
        $event=Register-ObjectEvent -InputObject $c2 -EventName InfoMessage -Action {
            $msg=$event.SourceEventArgs.Message
            if($msg -match 'percent'){Write-Output ('PROGRESS: '+$msg)}
        }
    }catch{}

    Write-Output 'Backup started with COMPRESSION...'
    $cmd3.ExecuteNonQuery()
    Write-Output 'BACKUP COMPLETE!'

    # Check file size
    $cmd4=$c2.CreateCommand()
    $cmd4.CommandText="EXEC xp_cmdshell 'dir D:\Backup\UFDATA_001_2020_FULL_20260626.bak'"
    $r2=$cmd4.ExecuteReader()
    while($r2.Read()){
        $line=$r2[0]
        if($line -and $line -match '\d+.*bytes'){
            Write-Output ('FILE: '+$line.Trim())
        }
    }
    $r2.Close()
    $c2.Close()
    $c.Close()

}catch{
    Write-Output ('ERROR: '+$_.Exception.Message)
}

Write-Output '=== DONE ==='
