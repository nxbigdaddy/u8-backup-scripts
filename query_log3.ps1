$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\log_analysis3.txt'

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

    $output += "=== UA_Log Module Total (all years) ==="
    $output += (RunQ "SELECT cSub_Id, count(*) as cnt FROM UA_Log GROUP BY cSub_Id ORDER BY count(*) DESC")

    $output += "`n=== UA_Log Time Range ==="
    $output += (RunQ "SELECT MIN(dInTime), MAX(dInTime) FROM UA_Log WHERE dInTime IS NOT NULL")

    $output += "`n=== UA_Log Top 20 Users ==="
    $output += (RunQ "SELECT TOP 20 cUser_Id, count(*) as cnt FROM UA_Log GROUP BY cUser_Id ORDER BY count(*) DESC")

    $output += "`n=== UA_Log Top 20 Stations ==="
    $output += (RunQ "SELECT TOP 20 cStation, count(*) as cnt FROM UA_Log WHERE cStation IS NOT NULL GROUP BY cStation ORDER BY count(*) DESC")

    $output += "`n=== UA_AALog_base Time Range ==="
    $output += (RunQ "SELECT MIN(dInTime), MAX(dInTime) FROM UA_AALog_base WHERE dInTime IS NOT NULL")

    $output += "`n=== UA_AALog_base Module + Year ==="
    $output += (RunQ @"
SELECT TOP 30 cSub_Id, iyear, count(*) as cnt 
FROM UA_AALog_base 
GROUP BY cSub_Id, iyear 
ORDER BY count(*) DESC
"@)

    $conn.Close()
    
    $output -join "`n" | Out-File -FilePath $outFile -Encoding UTF8
    "Done." | Write-Output
} catch {
    "OUTER ERROR: $_" | Out-File -FilePath '<workspace>\U8-T\log_analysis3.txt' -Encoding UTF8 -Append
    "OUTER ERROR: $_" | Write-Output
}
