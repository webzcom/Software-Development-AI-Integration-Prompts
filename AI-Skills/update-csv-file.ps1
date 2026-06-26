$CsvFile = "C:\SiteSpy\SiteSpy-History.csv"

# powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\AI-Skills\update-csv-file.ps1"

$row = [PSCustomObject]@{
    ScanTime   = Get-Date
    IP         = "192.168.1.25"
    StatusCode = "404"
    Requests   = 12
    Subnet     = "192.168.1.0/24"
    Action     = "Added to SiteSpy Zone"
}

$row | Export-Csv -Path $CsvFile -Append -NoTypeInformation
