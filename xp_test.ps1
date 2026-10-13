$ErrorActionPreference='Continue'
$log='<workspace>\U8-T\xp_cmdshell_test.txt'
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

# Check if xp_cmdshell works
$o+='=== xp_cmdshell test ==='
$o+=(RunXP 'echo hello')

# Check if scp exists
$o+=''
$o+='=== scp check ==='
$o+=(RunXP 'where scp 2>&1')

# Check D: drive space  
$o+=''
$o+='=== D: drive ==='
$o+=(RunXP 'dir D:\Backup 2>&1')

# Check if backup file exists
$o+=''
$o+='=== Backup file ==='
$o+=(RunXP 'dir D:\Backup\*.bak 2>&1')

$o -join "`n" | Out-File -FilePath $log -Encoding UTF8
$c.Close()
Write-Output 'OK'
