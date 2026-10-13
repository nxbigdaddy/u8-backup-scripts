$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\backup_final.txt'
$o=@()

# Step 1: Write the backup SQL file locally
$sqlFile = '<workspace>\U8-T\bk_cmd.sql'
@"
BACKUP DATABASE [UFDATA_001_2020] 
TO DISK = N'C:\Backup\UFDATA_001_2020_FULL_20260626.bak' 
WITH COMPRESSION, INIT, STATS = 10
"@ | Out-File -FilePath $sqlFile -Encoding ASCII
$o+="SQL file written locally"

# Step 2: Copy SQL file to server via xp_cmdshell (base64 encode to avoid encoding issues)
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content $sqlFile -Raw)))
$o+="Base64 length: $($b64.Length)"

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Decode on server and write file
$decodeCmd = "powershell -NoProfile -Command `"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('$b64')) | Out-File -FilePath C:\Backup\bk_cmd.sql -Encoding ASCII`""

$cmd=$c.CreateCommand()
$cmd.CommandText="EXEC xp_cmdshell '$decodeCmd'"
$cmd.CommandTimeout=10
try{$cmd.ExecuteNonQuery()|Out-Null;$o+='SQL file deployed to server'}catch{$o+=('Deploy err: '+$_.Exception.Message)}

# Step 3: Run backup via sqlcmd using the file
$exeCmd="sqlcmd -S . -U sa -P YOUR_DB_PASSWORD -i C:\Backup\bk_cmd.sql -o C:\Backup\bk_output.txt"
$cmd2=$c.CreateCommand()
$cmd2.CommandText="EXEC xp_cmdshell '$exeCmd'"
$cmd2.CommandTimeout=30
$o+=''
$o+="Launching backup at $(Get-Date)"

try{
    $cmd2.ExecuteNonQuery()|Out-Null
    $o+='sqlcmd backup process launched (detached from this session)'
}catch{$o+=('Launch err: '+$_.Exception.Message)}

# Step 4: Verify
Start-Sleep -s 3
$cmd3=$c.CreateCommand()
$cmd3.CommandText="SELECT session_id, command, status, percent_complete FROM sys.dm_exec_requests WHERE command LIKE '%BACKUP%'"
$r=$cmd3.ExecuteReader()
$found=0
while($r.Read()){
    $found=1
    $o+=('BACKUP: Sess:{0} Status:{1} Pct:{2}%' -f $r[0],$r[2],[Math]::Round([double]$r[3],1))
}
$r.Close()
if($found -eq 0){$o+='No backup session - it may have completed already or failed'}

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
