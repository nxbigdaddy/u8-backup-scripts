$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_echo.txt'
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

$o+="Time: $(Get-Date)"

# Step 1: Write SQL file line by line
$o+=''
$o+='Writing SQL file...'
RunXP 'echo BACKUP DATABASE [UFDATA_001_2020] > C:\Backup\bk.sql'
RunXP 'echo TO DISK = N''C:\Backup\UFDATA_001_2020_FULL.bak'' >> C:\Backup\bk.sql'
RunXP 'echo WITH COMPRESSION, INIT, STATS = 10 >> C:\Backup\bk.sql'
$o+='SQL file written'

# Verify content
$o+=''
$o+='SQL file content:'
$o+=(RunXP 'type C:\Backup\bk.sql')

# Step 2: Launch detached backup
$o+=''
$o+="Launching detached backup at $(Get-Date)"
RunXP 'start /B sqlcmd -S . -U sa -P YOUR_DB_PASSWORD -i C:\Backup\bk.sql -o C:\Backup\bk_log.txt'
$o+='Detached process launched!'

# Step 3: Verify
Start-Sleep -s 5
$cmd3=$c.CreateCommand()
$cmd3.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r3=$cmd3.ExecuteReader()
$found=0
while($r3.Read()){
    $found=1
    $o+=('BACKUP: Sess:{0} Status:{1} Pct:{2}%' -f $r3[0],$r3[2],[Math]::Round([double]$r3[3],1))
}
$r3.Close()
if($found -eq 0){$o+='No backup session'}

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
