$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\agent_check.txt'
$o=@()

$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

# Check SQL Agent
$cmd=$c.CreateCommand()
$cmd.CommandText="SELECT CAST(SERVERPROPERTY('Edition') AS VARCHAR(40)) AS Edition,
   (SELECT CASE WHEN EXISTS(SELECT 1 FROM sys.dm_server_services WHERE servicename LIKE '%SQLAgent%' AND status_desc='Running') THEN 'AGENT_RUNNING' ELSE 'AGENT_NOT_RUNNING' END) AS AgentStatus"
$r=$cmd.ExecuteReader()
while($r.Read()){$o+=('Edition: '+$r[0]);$o+=('Agent: '+$r[1])}
$r.Close()

# Check if sp_start_job exists
$o+=''
try{
    $cmd2=$c.CreateCommand()
    $cmd2.CommandText="SELECT COUNT(*) FROM msdb.dbo.sysjobs WHERE name='_TEMP_U8_BACKUP'"
    $cnt=$cmd2.ExecuteScalar()
    $o+="Existing temp job count: $cnt"
}catch{$o+=('Check err: '+$_.Exception.Message)}

# Check sqlcmd availability
$cmd3=$c.CreateCommand()
$cmd3.CommandText="EXEC xp_cmdshell 'where sqlcmd 2>&1'"
$r3=$cmd3.ExecuteReader()
$o+=''
$o+='sqlcmd:'
while($r3.Read()){$v=$r3[0];if($v-and$v.ToString().Trim()-ne''){$o+=('  '+$v.ToString().Trim())}}
$r3.Close()

# Check if we can write a batch file
$cmd4=$c.CreateCommand()
$cmd4.CommandText="EXEC xp_cmdshell 'dir C:\Backup\ 2>&1'"
$r4=$cmd4.ExecuteReader()
$o+=''
$o+='C:\Backup dir:'
while($r4.Read()){$v=$r4[0];if($v-and$v.ToString().Trim()-ne''){$o+=('  '+$v.ToString().Trim())}}
$r4.Close()

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output ($o -join "`n")
