$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\disk_check.txt'
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

$o+='=== All Drives ==='
$o+=(RunXP 'wmic logicaldisk get name,size,freespace')

$o+=''
$o+='=== Backup file now ==='
$o+=(RunXP 'dir D:\Backup\*.bak')

# Check for running backup process
$o+=''
$o+='=== Processes ==='
$o+=(RunXP 'tasklist /fi "imagename eq sqlservr.exe" 2>&1')

$c.Close()
$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
Write-Output 'OK'
