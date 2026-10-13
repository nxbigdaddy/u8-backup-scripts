$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_task.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Step 1: Write the batch file using xp_cmdshell (no special chars in path)
$batPath='C:\Backup\bk_go.bat'

# Write line by line, avoid special chars
$lines = @(
    '@echo off',
    'echo %date% %time% Start > C:\Backup\bk_log.txt',
    'sqlcmd -S localhost -U sa -P YOUR_DB_PASSWORD -i C:\Backup\bk.sql -o C:\Backup\bk_out.txt',
    'echo %date% %time% Done >> C:\Backup\bk_log.txt'
)

$cmd=$c.CreateCommand()
$cmd.CommandText="EXEC xp_cmdshell 'echo @echo off > $batPath'"
$cmd.ExecuteNonQuery()|Out-Null

$cmd.CommandText="EXEC xp_cmdshell 'echo echo Start ^> C:\Backup\bk_log.txt >> $batPath'"
$cmd.ExecuteNonQuery()|Out-Null

$cmd.CommandText="EXEC xp_cmdshell 'echo sqlcmd -S localhost -U sa -P YOUR_DB_PASSWORD -i C:\Backup\bk.sql -o C:\Backup\bk_out.txt >> $batPath'"
$cmd.ExecuteNonQuery()|Out-Null

$cmd.CommandText="EXEC xp_cmdshell 'echo echo Done ^>^> C:\Backup\bk_log.txt >> $batPath'"
$cmd.ExecuteNonQuery()|Out-Null

$o+='Batch file written'

# Step 2: Write the SQL file
$cmd.CommandText="EXEC xp_cmdshell 'echo BACKUP DATABASE [UFDATA_001_2020] > C:\Backup\bk.sql'"
$cmd.ExecuteNonQuery()|Out-Null

$cmd.CommandText="EXEC xp_cmdshell 'echo TO DISK = N''C:\Backup\UF_001_2020_FULL.bak'' >> C:\Backup\bk.sql'"
$cmd.ExecuteNonQuery()|Out-Null

$cmd.CommandText="EXEC xp_cmdshell 'echo WITH COMPRESSION, INIT >> C:\Backup\bk.sql'"
$cmd.ExecuteNonQuery()|Out-Null

$o+='SQL file written'

# Verify files
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell 'type C:\Backup\bk.sql'"
$r=$cmd2.ExecuteReader()
$o+=''
$o+='SQL content:'
while($r.Read()){
    $v=$r[0]
    if($v-and$v.ToString().Trim()-ne''){$o+=('  '+$v.ToString().Trim())}
}
$r.Close()

# Step 3: Remove old task if exists
$cmd.CommandText="EXEC xp_cmdshell 'schtasks /delete /tn U8_Backup /f 2>nul'"
$cmd.ExecuteNonQuery()|Out-Null

# Step 4: Create scheduled task
$trCmd = "cmd /c C:\Backup\bk_go.bat"
$cmd.CommandText="EXEC xp_cmdshell 'schtasks /create /tn U8_Backup /tr `"$trCmd`" /sc once /st 00:00 /f'"
try{
    $r2=$cmd.ExecuteReader()
    while($r2.Read()){
        $v=$r2[0]
        if($v-and$v.ToString().Trim()-ne''){$o+=('  '+$v.ToString().Trim())}
    }
    $r2.Close()
    $o+='Task created'
}catch{$o+=('Task create err: '+$_.Exception.Message)}

# Step 5: Run now
$cmd.CommandText="EXEC xp_cmdshell 'schtasks /run /tn U8_Backup'"
try{
    $r3=$cmd.ExecuteReader()
    while($r3.Read()){
        $v=$r3[0]
        if($v-and$v.ToString().Trim()-ne''){$o+=('  '+$v.ToString().Trim())}
    }
    $r3.Close()
    $o+='Task triggered!'
}catch{$o+=('Run err: '+$_.Exception.Message)}

# Step 6: Check
Start-Sleep -s 5
$cmd4=$c.CreateCommand()
$cmd4.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r4=$cmd4.ExecuteReader()
while($r4.Read()){
    $o+=('BACKUP: Sess:{0} {1} {2}%' -f $r4[0],$r4[2],[Math]::Round([double]$r4[3],1))
}
$r4.Close()

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
