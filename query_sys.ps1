$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\system_info.txt'

try {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = 'Server=203.0.113.10;Database=UFSystem;User ID=sa;Password=YOUR_PASSWORD;Connection Timeout=10'
    $conn.Open()

    function RunQ($sql) {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
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
    }

    $output = @()

    $output += "=== COLUMNS: UA_Account ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_Account'")

    $output += "`n=== UA_Account (SELECT *) ==="
    $output += (RunQ "SELECT TOP 1 * FROM UA_Account")

    $output += "`n=== COLUMNS: UA_User ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_User'")

    $output += "`n=== UA_User (SELECT *) ==="
    $output += (RunQ "SELECT * FROM UA_User")

    $output += "`n=== COLUMNS: UA_Role ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_Role'")

    $output += "`n=== UA_Role (SELECT *) ==="
    $output += (RunQ "SELECT * FROM UA_Role")

    $output += "`n=== COLUMNS: UA_Account_Sub ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_Account_sub'")

    $output += "`n=== UA_Account_Sub (SELECT *) ==="
    $output += (RunQ "SELECT * FROM UA_Account_Sub")

    $output += "`n=== COLUMNS: UA_Period ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_Period'")

    $output += "`n=== UA_Period ==="
    $output += (RunQ "SELECT * FROM UA_Period")

    $output += "`n=== COLUMNS: UA_UserRelation ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_UserRelation'")

    $output += "`n=== UA_UserRelation ==="
    $output += (RunQ "SELECT * FROM UA_UserRelation")

    $output += "`n=== COLUMNS: UA_Identity ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_Identity'")

    $output += "`n=== UA_Identity ==="
    $output += (RunQ "SELECT * FROM UA_Identity")

    $output += "`n=== COLUMNS: UA_BackupPlan ==="
    $output += (RunQ "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_BackupPlan'")

    $output += "`n=== UA_BackupPlan ==="
    $output += (RunQ "SELECT * FROM UA_BackupPlan")

    $output += "`n=== COLUMNS: UA_HoldAuth ==="
    $output += (RunQ "SELECT TOP 1 COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='UA_HoldAuth'")

    $output += "`n=== UA_HoldAuth (top 5) ==="
    $output += (RunQ "SELECT TOP 5 * FROM UA_HoldAuth")

    $conn.Close()
    
    $output -join "`n" | Out-File -FilePath $outFile -Encoding UTF8
    "Done. Output written to $outFile" | Write-Output
} catch {
    "ERROR: $_" | Out-File -FilePath '<workspace>\U8-T\system_info.txt' -Encoding UTF8 -Append
    "ERROR: $_" | Write-Output
}
