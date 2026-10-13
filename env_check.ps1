$ErrorActionPreference='Stop'
$out='<workspace>\U8-T\env_check.txt'
$o=@()

# Test 1: Linux SQL
try{
    $c=New-Object System.Data.SqlClient.SqlConnection
    $c.ConnectionString='Server=203.0.113.10,1433;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
    $c.Open()
    $o+='Linux SQL: OK'
    $cmd=$c.CreateCommand()
    $cmd.CommandText="SELECT @@VERSION AS Ver, CAST(SERVERPROPERTY('Edition') AS VARCHAR(60)) AS Ed, CAST(SERVERPROPERTY('EngineEdition') AS INT) AS Eng"
    $r=$cmd.ExecuteReader()
    while($r.Read()){$o+=('Ver: '+$r[0]);$o+=('Edition: '+$r[1]);$o+=('Engine: '+$r[2])}
    $r.Close()

    # Check disk space via SQL
    $cmd2=$c.CreateCommand()
    $cmd2.CommandText="EXEC xp_fixeddrives"
    $r2=$cmd2.ExecuteReader()
    $o+='Disk:'
    while($r2.Read()){$o+=('  '+$r2[0]+': '+$r2[1]+' MB free')}
    $r2.Close()

    # Check existing databases
    $cmd3=$c.CreateCommand()
    $cmd3.CommandText="SELECT name, CAST(size*8.0/1024 AS DECIMAL(18,1)) AS SizeMB FROM sys.master_files WHERE database_id>4 ORDER BY size DESC"
    $r3=$cmd3.ExecuteReader()
    $o+='Existing DBs:'
    while($r3.Read()){$o+=('  '+$r3[0]+' | '+$r3[1].ToString()+' MB')}
    $r3.Close()
    $c.Close()
}catch{$o+=('Linux SQL ERR: '+$_.Exception.Message)}

# Test 2: Win backup path
try{
    $c2=New-Object System.Data.SqlClient.SqlConnection
    $c2.ConnectionString='Server=203.0.113.10;User ID=sa;Password=YOUR_PASSWORD;Timeout=10'
    $c2.Open()
    $o+='Win SQL: OK'
    $cmd=$c2.CreateCommand()
    $cmd.CommandText="SELECT physical_name, CAST(size*8.0/1024 AS int) AS SizeMB FROM UFDATA_001_2020.sys.database_files"
    $r=$cmd.ExecuteReader()
    $o+='Win Files:'
    while($r.Read()){$o+=('  '+$r[0]+' = '+$r[1].ToString()+' MB')}
    $r.Close()
    $c2.Close()
}catch{$o+=('Win SQL ERR: '+$_.Exception.Message)}

$o -join "`n" | Out-File -FilePath $out -Encoding UTF8
Write-Output 'OK'
