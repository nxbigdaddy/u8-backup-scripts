$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\log_analysis2.txt'

try {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = 'Server=203.0.113.10;Database=UFSystem;User ID=sa;Password=YOUR_PASSWORD;Connection Timeout=10'
    $conn.Open()

    function RunQ($sql) {
        try {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $sql
            $cmd.CommandTimeout = 120
            $reader = $cmd.ExecuteReader()
            $rows = @()
            while ($reader.Read()) {
                $row = @()
                for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                    $val = $reader.GetValue($i)
                    if ($val -eq $null -or $val -eq [DBNull]::Value) {
                        $row += '(null)'
                    } else {
                        $row += $val.ToString()
                    }
                }
                $rows += ($row -join ' | ')
            }
            $reader.Close()
            if ($rows.Count -eq 0) { return '(no rows)' }
            return $rows -join "`n"
        } catch {
            return "ERR: $($_.Exception.Message)"
        }
    }

    $output = @()

    $output += "==================== UA_Log 按模块 (cSub_Id) 统计 ===================="
    $output += (RunQ "SELECT cSub_Id AS 模块, count(*) AS 日志条数 FROM UA_Log GROUP BY cSub_Id ORDER BY count(*) DESC")

    $output += "`n==================== UA_Log 按年份统计 ===================="
    $output += (RunQ "SELECT iyear AS 年份, count(*) AS 日志条数 FROM UA_Log GROUP BY iyear ORDER BY iyear")

    $output += "`n==================== UA_Log 按模块+年份 TOP 50 ===================="
    $output += (RunQ @"
SELECT TOP 50 cSub_Id, iyear, count(*) AS cnt 
FROM UA_Log 
GROUP BY cSub_Id, iyear 
ORDER BY count(*) DESC
"@)

    $output += "`n==================== UA_Log 最活跃用户 TOP 20 ===================="
    $output += (RunQ "SELECT TOP 20 cUser_Id, count(*) AS 操作次数 FROM UA_Log GROUP BY cUser_Id ORDER BY count(*) DESC")

    $output += "`n==================== UA_Log 成功/失败比例 ===================="
    $output += (RunQ "SELECT Success, count(*) AS cnt FROM UA_Log GROUP BY Success")

    $output += "`n==================== UA_AALog_base 按模块 (cSub_Id) 统计 ===================="
    $output += (RunQ "SELECT cSub_Id, count(*) AS cnt FROM UA_AALog_base GROUP BY cSub_Id ORDER BY count(*) DESC")

    $output += "`n==================== UA_AALog_base 按 cLog_ID 统计 TOP 20 ===================="
    $output += (RunQ "SELECT TOP 20 cLog_ID, count(*) AS cnt FROM UA_AALog_base GROUP BY cLog_ID ORDER BY count(*) DESC")

    $output += "`n==================== UA_AALog_base 最活跃用户 TOP 20 ===================="
    $output += (RunQ "SELECT TOP 20 cUser_Id, count(*) AS cnt FROM UA_AALog_base GROUP BY cUser_Id ORDER BY count(*) DESC")

    $output += "`n==================== UA_Log 时间段分布 (最近日志) ===================="
    $output += (RunQ "SELECT MIN(dInTime) AS 最早, MAX(dInTime) AS 最近 FROM UA_Log WHERE dInTime IS NOT NULL")

    $output += "`n==================== UA_AALog_base 时间段分布 ===================="
    $output += (RunQ "SELECT MIN(dInTime) AS 最早, MAX(dInTime) AS 最近 FROM UA_AALog_base WHERE dInTime IS NOT NULL")

    $conn.Close()
    
    $output -join "`n" | Out-File -FilePath $outFile -Encoding UTF8
    "Done." | Write-Output
} catch {
    "OUTER ERROR: $_" | Out-File -FilePath '<workspace>\U8-T\log_analysis2.txt' -Encoding UTF8 -Append
    "OUTER ERROR: $_" | Write-Output
}
