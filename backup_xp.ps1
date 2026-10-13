$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_xp.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Step 1: Write backup SQL to a file on the server
$sqlContent = @"
BACKUP DATABASE [UFDATA_001_2020] 
TO DISK = N'C:\Backup\UFDATA_001_2020_FULL_20260626.bak' 
WITH COMPRESSION, INIT, STATS = 10
"@

# Escape for cmd echo
$escaped = $sqlContent -replace '"', '""' -replace '%', '%%'
# Write via xp_cmdshell echo
$cmd=$c.CreateCommand()
$cmd.CommandText="EXEC xp_cmdshell 'echo $escaped > C:\Backup\backup_cmd.sql'"
try{$cmd.ExecuteNonQuery() | Out-Null;$o+='Wrote SQL file'}catch{$o+=('Write err: '+$_.Exception.Message)}

# Step 2: Execute the SQL via sqlcmd
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell 'sqlcmd -S . -U sa -P ""YOUR_DB_PASSWORD"" -i C:\Backup\backup_cmd.sql -o C:\Backup\backup_output.txt'"
$cmd2.CommandTimeout=30
$o+="Launching sqlcmd backup at $(Get-Date)"

try{
    $cmd2.ExecuteNonQuery() | Out-Null
    $o+='sqlcmd launched successfully'
}catch{
    $o+=('Launch err: '+$_.Exception.Message)
}

Start-Sleep -Seconds 2

# Step 3: Verify
$cmd3=$c.CreateCommand()
$cmd3.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r3=$cmd3.ExecuteReader()
while($r3.Read()){
    $o+=('BACKUP: Session:{0} Status:{1} Pct:{2}%' -f $r3[0],$r3[2],[Math]::Round([double]$r3[3],1))
}
$r3.Close()

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
