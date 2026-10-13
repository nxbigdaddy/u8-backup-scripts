$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\year_check.txt'

try {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = 'Server=203.0.113.10;Database=UFSystem;User ID=sa;Password=YOUR_PASSWORD;Connection Timeout=10'
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
                    if ($val -eq $null -or $val -eq [DBNull]::Value) { $row += '(null)' }
                    else { $row += $val.ToString() }
                }
                $rows += ($row -join ' | ')
            }
            $reader.Close()
            if ($rows.Count -eq 0) { return '(no rows)' }
            return $rows -join "`n"
        } catch { return "ERR: $($_.Exception.Message)" }
    }

    $output = @()

    # 1. 查看所有年份的 GL 凭证分布 - 最关键
    $output += "=== GL_accvouch by Year ==="
    $output += (RunQ @"
SELECT LEFT(CONVERT(varchar, dbill_date, 23), 4) AS yr, 
       COUNT(*) AS vouchers,
       SUM(md) AS debit_sum,
       SUM(mc) AS credit_sum
FROM UFDATA_001_2020.dbo.GL_accvouch 
WHERE dbill_date IS NOT NULL 
GROUP BY LEFT(CONVERT(varchar, dbill_date, 23), 4) 
ORDER BY yr
"@)

    # 2. 各模块主表年度分布
    $output += "`n=== RdRecord01 by Year ==="
    $output += (RunQ "SELECT LEFT(CONVERT(varchar, dDate, 23), 4) AS yr, COUNT(*) AS cnt FROM UFDATA_001_2020.dbo.RdRecord01 WHERE dDate IS NOT NULL GROUP BY LEFT(CONVERT(varchar, dDate, 23), 4) ORDER BY yr")

    $output += "`n=== SaleBillVouch by Year ==="
    $output += (RunQ "SELECT LEFT(CONVERT(varchar, dDate, 23), 4) AS yr, COUNT(*) AS cnt FROM UFDATA_001_2020.dbo.SaleBillVouch WHERE dDate IS NOT NULL GROUP BY LEFT(CONVERT(varchar, dDate, 23), 4) ORDER BY yr")

    $output += "`n=== DispatchList by Year ==="
    $output += (RunQ "SELECT LEFT(CONVERT(varchar, dDate, 23), 4) AS yr, COUNT(*) AS cnt FROM UFDATA_001_2020.dbo.DispatchList WHERE dDate IS NOT NULL GROUP BY LEFT(CONVERT(varchar, dDate, 23), 4) ORDER BY yr")

    # 3. 当前的数据库文件大小
    $output += "`n=== Database File Sizes ==="
    $output += (RunQ @"
SELECT DB_NAME(database_id) AS DBName, 
       name AS FileName,
       CAST(size * 8.0 / 1024 AS DECIMAL(18,1)) AS SizeMB,
       CAST(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(18,1)) AS UsedMB
FROM UFDATA_001_2020.sys.database_files
"@)

    # 4. 检查 UFSystem 中是否已经有其他年度库注册
    $output += "`n=== UA_AccountDatabase (Registered DBs) ==="
    $output += (RunQ "SELECT * FROM UA_AccountDatabase")

    # 5. 检查是否实际存在其他 UFDATA_001_20XX 数据库
    $output += "`n=== All UFDATA Databases on Server ==="
    $output += (RunQ "SELECT name, create_date FROM sys.databases WHERE name LIKE 'UFDATA%' ORDER BY name")

    $conn.Close()
    
    $output -join "`n" | Out-File -FilePath $outFile -Encoding UTF8
    "Done." | Write-Output
} catch {
    "OUTER ERROR: $_" | Out-File -FilePath '<workspace>\U8-T\year_check.txt' -Encoding UTF8 -Append
    "OUTER ERROR: $_" | Write-Output
}
