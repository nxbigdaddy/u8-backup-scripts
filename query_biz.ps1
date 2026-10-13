$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\business_info.txt'

try {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = 'Server=203.0.113.10;Database=UFDATA_001_2020;User ID=sa;Password=YOUR_PASSWORD;Connection Timeout=10'
    $conn.Open()

    function RunQ($sql) {
        try {
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
        } catch {
            return "SQL ERROR: $($_.Exception.Message)"
        }
    }

    $output = @()

    $output += "=== Total Table Count ==="
    $output += (RunQ "SELECT count(*) FROM sys.tables")

    $output += "`n=== Row Counts: Master Data Tables ==="
    $output += (RunQ "SELECT 'Customer' AS tbl, count(*) as rows FROM Customer UNION ALL SELECT 'Vendor', count(*) as rows FROM Vendor UNION ALL SELECT 'Inventory', count(*) as rows FROM Inventory UNION ALL SELECT 'Department', count(*) as rows FROM Department UNION ALL SELECT 'Person', count(*) as rows FROM Person UNION ALL SELECT 'Warehouse', count(*) as rows FROM Warehouse")

    $output += "`n=== Row Counts: Voucher/Tx Tables ==="
    $output += (RunQ "SELECT 'SaleBillVouch' AS tbl, count(*) as rows FROM SaleBillVouch UNION ALL SELECT 'PurBillVouch', count(*) as rows FROM PurBillVouch UNION ALL SELECT 'DispatchList', count(*) as rows FROM DispatchList UNION ALL SELECT 'RdRecord01', count(*) as rows FROM RdRecord01 UNION ALL SELECT 'GL_accvouch', count(*) as rows FROM GL_accvouch")

    $output += "`n=== Row Counts: Receivable/Payable ==="
    $output += (RunQ "SELECT 'Ap_CloseBill' AS tbl, count(*) as rows FROM Ap_CloseBill UNION ALL SELECT 'Ap_Detail', count(*) as rows FROM Ap_Detail")

    $output += "`n=== AccInformation (Module Config) ==="
    $output += (RunQ "SELECT cSysID, cName, cValue FROM AccInformation WHERE cSysID IN ('GL','IA','AR','AP','FA','CA','PU','SA','ST','OM','PP','MP','QM','HR','PA') AND cName LIKE '%dDate%' ORDER BY cSysID")

    $output += "`n=== GL Vouch Years Distribution ==="
    $output += (RunQ "SELECT substring(convert(varchar, dbill_date, 23), 1, 4) as yr, count(*) as cnt FROM GL_accvouch WHERE dbill_date IS NOT NULL GROUP BY substring(convert(varchar, dbill_date, 23), 1, 4) ORDER BY yr")

    $output += "`n=== SaleBillVouch Years ==="
    $output += (RunQ "SELECT substring(convert(varchar, dDate, 23), 1, 4) as yr, count(*) as cnt FROM SaleBillVouch WHERE dDate IS NOT NULL GROUP BY substring(convert(varchar, dDate, 23), 1, 4) ORDER BY yr")

    $output += "`n=== PurBillVouch Years ==="
    $output += (RunQ "SELECT substring(convert(varchar, dDate, 23), 1, 4) as yr, count(*) as cnt FROM PurBillVouch WHERE dDate IS NOT NULL GROUP BY substring(convert(varchar, dDate, 23), 1, 4) ORDER BY yr")

    $output += "`n=== RdRecord01 Years ==="
    $output += (RunQ "SELECT substring(convert(varchar, dDate, 23), 1, 4) as yr, count(*) as cnt FROM RdRecord01 WHERE dDate IS NOT NULL GROUP BY substring(convert(varchar, dDate, 23), 1, 4) ORDER BY yr")

    $output += "`n=== DispatchList Years ==="
    $output += (RunQ "SELECT substring(convert(varchar, dDate, 23), 1, 4) as yr, count(*) as cnt FROM DispatchList WHERE dDate IS NOT NULL GROUP BY substring(convert(varchar, dDate, 23), 1, 4) ORDER BY yr")

    $conn.Close()
    
    $output -join "`n" | Out-File -FilePath $outFile -Encoding UTF8
    "Done. Output written to $outFile" | Write-Output
} catch {
    "OUTER ERROR: $_" | Out-File -FilePath '<workspace>\U8-T\business_info.txt' -Encoding UTF8 -Append
    "OUTER ERROR: $_" | Write-Output
}
