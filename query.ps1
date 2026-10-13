$ErrorActionPreference = 'Stop'
$outFile = '<workspace>\U8-T\query_result.txt'

try {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = 'Server=203.0.113.10;Database=UFSystem;User ID=sa;Password=YOUR_PASSWORD;Connection Timeout=10'
    $conn.Open()
    "Connected to UFSystem" | Out-File -FilePath $outFile -Encoding UTF8

    $tables = @()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = 'SELECT name FROM sys.tables ORDER BY name'
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $tables += $reader.GetValue(0).ToString()
    }
    $reader.Close()

    "Table count: $($tables.Count)" | Out-File -FilePath $outFile -Encoding UTF8 -Append
    $tables | Out-File -FilePath $outFile -Encoding UTF8 -Append

    $conn.Close()
    "Done" | Out-File -FilePath $outFile -Encoding UTF8 -Append
} catch {
    "ERROR: $_" | Out-File -FilePath $outFile -Encoding UTF8 -Append
}
