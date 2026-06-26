$ExcelFile = "C:\Temp\example.xlsx"
$WorksheetName = "Sheet1"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$workbook = $excel.Workbooks.Open($ExcelFile)
$sheet = $workbook.Worksheets.Item($WorksheetName)

# Find next empty row
$nextRow = $sheet.Cells($sheet.Rows.Count, 1).End(-4162).Row + 1
# -4162 = xlUp

# Add values
$sheet.Cells.Item($nextRow, 1).Value2 = Get-Date
$sheet.Cells.Item($nextRow, 2).Value2 = "PodGrabber"
$sheet.Cells.Item($nextRow, 3).Value2 = "New row added from PowerShell"

$workbook.Save()
$workbook.Close($true)
$excel.Quit()

# Clean up COM objects
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($sheet) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

[GC]::Collect()
[GC]::WaitForPendingFinalizers()
