$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\log_analysis.txt'

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

    $output += "==================== UA_Log 列信息 ===================="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_Log'")

    $output += "`n==================== UA_Log Row Count ===================="
    $output += (RunQ "SELECT count(*) FROM UA_Log")

    $output += "`n==================== UA_Log 样本 (前5行) ===================="
    $output += (RunQ "SELECT TOP 5 * FROM UA_Log ORDER BY cLog_Id DESC")

    $output += "`n==================== UA_AALog_base 列信息 ===================="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_AALog_base'")

    $output += "`n==================== UA_AALog_base Row Count ===================="
    $output += (RunQ "SELECT count(*) FROM UA_AALog_base")

    $output += "`n==================== UA_AALog_base 样本 (前3行) ===================="
    $output += (RunQ "SELECT TOP 3 * FROM UA_AALog_base")

    $output += "`n==================== UA_TaskLog 列信息 ===================="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_TaskLog'")

    $output += "`n==================== UA_TaskLog Row Count ===================="
    $output += (RunQ "SELECT count(*) FROM UA_TaskLog")

    $output += "`n==================== UA_TaskLog 样本 (前3行) ===================="
    $output += (RunQ "SELECT TOP 3 * FROM UA_TaskLog")

    $output += "`n==================== EAILog Row Count ===================="
    $output += (RunQ "SELECT count(*) FROM EAILog")

    $output += "`n==================== UA_BackupLog ===================="
    $output += (RunQ "SELECT cPlanName, dBeginDate, dEndDate, cResult FROM UA_BackupLog ORDER BY dBeginDate DESC")

    $conn.Close()
    
    $output -join "`n" | Out-File -FilePath $outFile -Encoding UTF8
    "Done." | Write-Output
} catch {
    "OUTER ERROR: $_" | Out-File -FilePath '<workspace>\U8-T\log_analysis.txt' -Encoding UTF8 -Append
    "OUTER ERROR: $_" | Write-Output
}
