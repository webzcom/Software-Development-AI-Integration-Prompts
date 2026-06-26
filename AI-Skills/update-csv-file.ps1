$CsvFile = "C:\scripts\AI-Skills\history.csv"

$Header = "ScanTime,IP,StatusCode,Requests,Subnet,Action"

if (-not (Test-Path $CsvFile)) {
    $Header | Out-File -FilePath $CsvFile -Encoding UTF8
}

$ScanTime = "2026-06-26 10:30:00"
$IP = "192.168.1.25"
$StatusCode = "404"
$Requests = "12"
$Subnet = "192.168.1.0/24"
$Action = "Added to SiteSpy Zone"

$Line = "$ScanTime,$IP,$StatusCode,$Requests,$Subnet,$Action"

$Line | Out-File -FilePath $CsvFile -Append -Encoding UTF8
