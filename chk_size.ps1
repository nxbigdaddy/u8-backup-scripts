$ErrorActionPreference='Stop'
$out='<workspace>\U8-T\db_size.txt'
$c=New-Object System.Data.SqlClient.SqlConnection
$c.ConnectionString='Server=203.0.113.10;Database=UFDATA_001_2020;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
$c.Open()

function RunSQL($sql){
    $cmd=$c.CreateCommand()
    $cmd.CommandText=$sql
    $rdr=$cmd.ExecuteReader()
    $rows=@()
    while($rdr.Read()){
        $row=@()
        for($i=0;$i-lt$rdr.FieldCount;$i++){
            $v=$rdr.GetValue($i)
            if($v -eq $null -or $v -eq [DBNull]::Value){$row+='-'}
            else{$row+=$v.ToString()}
        }
        $rows+=($row -join ' | ')
    }
    $rdr.Close()
    if($rows.Count -eq 0){return '(empty)'}
    return $rows -join "`n"
}

$o=@()
$o+="=== DB File Sizes ==="
$sql1="SELECT name, type_desc, CAST(size*8.0/1024 AS int) AS SizeMB FROM UFDATA_001_2020.sys.database_files"
$o+=(RunSQL $sql1)

$o+="`n=== All DB Sizes ==="
$sql2="SELECT d.name, CAST(SUM(f.size)*8.0/1024 AS int) AS TotalMB FROM sys.master_files f JOIN sys.databases d ON f.database_id=d.database_id WHERE d.name LIKE 'UFDATA%' OR d.name='UFSystem' GROUP BY d.name ORDER BY TotalMB DESC"
$o+=(RunSQL $sql2)

$o+="`n=== SpaceUsed ==="
$sql3="SELECT name, CAST(CAST(FILEPROPERTY(name,'SpaceUsed')AS bigint)*8.0/1024 AS int) AS UsedMB FROM UFDATA_001_2020.sys.database_files"
$o+=(RunSQL $sql3)

$o -join "`n" | Out-File -FilePath $out -Encoding UTF8
$c.Close()
Write-Output 'OK'
