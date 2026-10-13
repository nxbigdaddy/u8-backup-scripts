$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\biz_module_analysis.txt'

try {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = 'Server=203.0.113.10;Database=UFDATA_001_2020;User ID=sa;Password=YOUR_PASSWORD;Connection Timeout=10'
    $conn.Open()

    function RunQ($sql) {
        try {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $sql
            $cmd.CommandTimeout = 180
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

    $output += "=== Tables by Module Prefix ==="
    $prefixes = @('GL','Ap','AR','IA','PU','SA','ST','OM','MO','PP','MP','BO','FA','CA','CM','QM','HR','PA','EC','AM','FC','NB','EX','SC','EQ','BG','MR','DP','AS')
    foreach ($p in $prefixes) {
        $cnt = (RunQ "SELECT count(*) FROM sys.tables WHERE name LIKE '$p%'")
        $output += "$p tables: $cnt"
    }

    $output += "`n=== Key GL Vouchers ==="
    $output += (RunQ "SELECT 'GL_accvouch' as t, count(*) as cnt FROM GL_accvouch")

    $output += "`n=== Key PU (Purchase) ==="
    $output += (RunQ "SELECT 'PurBillVouch' as t, count(*) as cnt FROM PurBillVouch UNION ALL SELECT 'PurSettleVouch', count(*) FROM PurSettleVouch UNION ALL SELECT 'PO_Pomain', count(*) FROM PO_Pomain")

    $output += "`n=== Key SA (Sales) ==="
    $output += (RunQ "SELECT 'SaleBillVouch' as t, count(*) as cnt FROM SaleBillVouch UNION ALL SELECT 'DispatchList', count(*) FROM DispatchList UNION ALL SELECT 'SO_SOMain', count(*) FROM SO_SOMain")

    $output += "`n=== Key ST (Inventory) ==="
    $output += (RunQ "SELECT 'RdRecord01' as t, count(*) as cnt FROM RdRecord01 UNION ALL SELECT 'RdRecords01', count(*) FROM RdRecords01 UNION ALL SELECT 'CurrentStock', count(*) FROM CurrentStock")

    $output += "`n=== Key AP (Payables) ==="
    $output += (RunQ "SELECT 'Ap_Detail' as t, count(*) as cnt FROM Ap_Detail UNION ALL SELECT 'Ap_CloseBill', count(*) FROM Ap_CloseBill UNION ALL SELECT 'Ap_Vouch', count(*) FROM Ap_Vouch")

    $output += "`n=== Key MO (Manufacturing) ==="
    $output += (RunQ "SELECT 'Mom_Order' as t, count(*) as cnt FROM Mom_Order UNION ALL SELECT 'Mom_OrderDetail', count(*) FROM Mom_OrderDetail UNION ALL SELECT 'Mom_Moallocate', count(*) FROM Mom_Moallocate")

    $output += "`n=== Key OM (Outsource) ==="
    $output += (RunQ "SELECT 'OM_MOMain' as t, count(*) as cnt FROM OM_MOMain UNION ALL SELECT 'OM_MODetails', count(*) FROM OM_MODetails")

    $output += "`n=== Key CM (Contract) ==="
    $output += (RunQ "SELECT 'CM_Balances' as t, count(*) as cnt FROM CM_Balances UNION ALL SELECT 'CM_Contract_A', count(*) FROM CM_Contract_A")

    $output += "`n=== Key FA (Fixed Assets) ==="
    $output += (RunQ "SELECT 'FA_Cards' as t, count(*) as cnt FROM FA_Cards UNION ALL SELECT 'FA_Total', count(*) FROM FA_Total")

    $output += "`n=== Key CA (Cost) ==="
    $output += (RunQ "SELECT 'CA_ComPDiff' as t, count(*) as cnt FROM CA_ComPDiff UNION ALL SELECT 'CA_EnMOP', count(*) FROM CA_EnMOP")

    $output += "`n=== Key QM (Quality) ==="
    $output += (RunQ "SELECT 'QM_CheckVouch' as t, count(*) as cnt FROM QM_CheckVouch UNION ALL SELECT 'QM_CheckVouchs', count(*) FROM QM_CheckVouchs")

    $output += "`n=== Key EC (Engineering Change) ==="
    $output += (RunQ "SELECT 'EC_CN' as t, count(*) as cnt FROM EC_CN")

    $output += "`n=== Key BG/BO (Budget) ==="
    $output += (RunQ "SELECT 'BG_Budget' as t, count(*) as cnt FROM BG_Budget")

    $conn.Close()
    
    $output -join "`n" | Out-File -FilePath $outFile -Encoding UTF8
    "Done." | Write-Output
} catch {
    "OUTER ERROR: $_" | Out-File -FilePath '<workspace>\U8-T\biz_module_analysis.txt' -Encoding UTF8 -Append
    "OUTER ERROR: $_" | Write-Output
}
