param(
    # Folder that contains the IIS log files.
    [Parameter(Mandatory = $false)]
    [string]$LogFolder = (Join-Path -Path $PSScriptRoot -ChildPath 'W3SVC4\W3SVC4'),

    # Markdown file that will be created.
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath 'web-traffic-report.md'),

    # Number of rows to show in the top sections.
    [Parameter(Mandatory = $false)]
    [int]$TopCount = 25
)

$ErrorActionPreference = 'Stop'

function Test-IsBlank {
    param(
        [string]$Value
    )

    return ($null -eq $Value -or $Value -match '^\s*$')
}

function Convert-LogLineToEntry {
    param(
        [string]$Line,
        [string[]]$FieldNames
    )

    if (Test-IsBlank -Value $Line) {
        return $null
    }

    $values = $Line.Trim() -split '\s+'
    if ($values.Count -lt $FieldNames.Count) {
        return $null
    }

    $entry = @{}
    for ($i = 0; $i -lt $FieldNames.Count; $i++) {
        $entry[$FieldNames[$i]] = $values[$i]
    }

    return $entry
}

function Normalize-UriStem {
    param(
        [string]$UriStem
    )

    if (Test-IsBlank -Value $UriStem) {
        return '/'
    }

    $cleanValue = $UriStem.Trim()
    if (-not $cleanValue.StartsWith('/')) {
        $cleanValue = '/' + $cleanValue
    }

    return $cleanValue.ToLower()
}

function Test-IsPageRequest {
    param(
        [string]$UriStem
    )

    $normalizedUri = Normalize-UriStem -UriStem $UriStem

    if ($normalizedUri -eq '/' -or $normalizedUri.EndsWith('/')) {
        return $true
    }

    $lastSlashIndex = $normalizedUri.LastIndexOf('/')
    $lastDotIndex = $normalizedUri.LastIndexOf('.')

    if ($lastDotIndex -lt 0 -or $lastDotIndex -lt $lastSlashIndex) {
        return $true
    }

    $extension = $normalizedUri.Substring($lastDotIndex)
    return ($extension -in @('.php', '.html', '.htm', '.asp', '.aspx', '.cgi', '.pl'))
}

function Get-ApplicationPath {
    param(
        [string]$UriStem
    )

    $normalizedUri = Normalize-UriStem -UriStem $UriStem
    $parts = @($normalizedUri.Trim('/') -split '/')

    if ($parts.Count -eq 0 -or (Test-IsBlank -Value $parts[0])) {
        return '/'
    }

    if ($parts[0] -ne 'applications') {
        return '/' + $parts[0]
    }

    if ($parts.Count -ge 3) {
        return '/' + $parts[0] + '/' + $parts[1] + '/' + $parts[2]
    }

    if ($parts.Count -ge 2) {
        return '/' + $parts[0] + '/' + $parts[1]
    }

    return '/applications'
}

function Get-MarkdownTableLines {
    param(
        [string[]]$Headers,
        [object[]]$Rows
    )

    $lines = @()
    $lines += '| ' + ($Headers -join ' | ') + ' |'

    $separatorCells = @()
    foreach ($header in $Headers) {
        $separatorCells += '---'
    }

    $lines += '| ' + ($separatorCells -join ' | ') + ' |'

    foreach ($row in $Rows) {
        $cells = @()
        foreach ($value in $row) {
            $text = '' + $value
            $text = $text -replace '\|', '\|'
            $cells += $text
        }

        $lines += '| ' + ($cells -join ' | ') + ' |'
    }

    return $lines
}

try {
    if (-not (Test-Path -LiteralPath $LogFolder -PathType Container)) {
        throw 'Log folder not found: ' + $LogFolder
    }

    $logFiles = @(Get-ChildItem -LiteralPath $LogFolder -Filter '*.log' -File | Sort-Object Name)
    if ($logFiles.Count -eq 0) {
        throw 'No log files were found in: ' + $LogFolder
    }

    $requests = @()

    foreach ($logFile in $logFiles) {
        $fieldNames = @()

        foreach ($line in Get-Content -LiteralPath $logFile.FullName) {
            if ($line -like '#Fields:*') {
                $fieldNames = @((($line -replace '^#Fields:\s*', '').Trim()) -split '\s+')
                continue
            }

            if ($line -like '#*') {
                continue
            }

            if ($fieldNames.Count -eq 0) {
                continue
            }

            $entry = Convert-LogLineToEntry -Line $line -FieldNames $fieldNames
            if ($null -eq $entry) {
                continue
            }

            $normalizedUri = Normalize-UriStem -UriStem $entry['cs-uri-stem']
            $statusCode = 0
            if ($entry['sc-status'] -match '^\d+$') {
                $statusCode = [int]$entry['sc-status']
            }

            $requestDateText = $entry['date'] + ' ' + $entry['time']

            $requests += @{
                LogFile          = $logFile.Name
                RequestDateTime  = $requestDateText
                RequestDate      = $entry['date']
                RequestTime      = $entry['time']
                Method           = $entry['cs-method']
                UriStem          = $normalizedUri
                UriQuery         = $entry['cs-uri-query']
                ApplicationPath  = Get-ApplicationPath -UriStem $normalizedUri
                ClientIp         = $entry['c-ip']
                UserName         = $entry['cs-username']
                StatusCode       = $statusCode
                SubStatus        = $entry['sc-substatus']
                TimeTaken        = $entry['time-taken']
                Referrer         = $entry['cs(Referer)']
                UserAgent        = $entry['cs(User-Agent)']
            }
        }
    }

    if ($requests.Count -eq 0) {
        throw 'No request entries could be read from the log files.'
    }

    $successfulRequests = @($requests | Where-Object { $_['StatusCode'] -ge 200 -and $_['StatusCode'] -lt 400 })
    $applicationRequests = @($successfulRequests | Where-Object { $_['ApplicationPath'] -like '/applications*' })
    $resourceRequestsWithoutNoise = @($successfulRequests | Where-Object { $_['UriStem'] -notin @('/favicon.ico') })
    $pageRequests = @($resourceRequestsWithoutNoise | Where-Object { Test-IsPageRequest -UriStem $_['UriStem'] })
    $errorRequests = @($requests | Where-Object { $_['StatusCode'] -ge 400 })

    $firstRequest = @($requests | Where-Object { -not (Test-IsBlank -Value $_['RequestDateTime']) } | Sort-Object { $_['RequestDateTime'] } | Select-Object -First 1)
    $lastRequest = @($requests | Where-Object { -not (Test-IsBlank -Value $_['RequestDateTime']) } | Sort-Object { $_['RequestDateTime'] } -Descending | Select-Object -First 1)

    $topApplications = @(
        $applicationRequests |
        Group-Object { $_['ApplicationPath'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $topResources = @(
        $resourceRequestsWithoutNoise |
        Group-Object { $_['UriStem'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $topPages = @(
        $pageRequests |
        Group-Object { $_['UriStem'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $topErrors = @(
        $errorRequests |
        Group-Object { $_['UriStem'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $statusSummary = @(
        $requests |
        Group-Object { $_['StatusCode'] } |
        Sort-Object Name |
        Select-Object -First $TopCount
    )

    $methodSummary = @(
        $requests |
        Group-Object { $_['Method'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $clientSummary = @(
        $successfulRequests |
        Group-Object { $_['ClientIp'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $clientPageSummary = @(
        $pageRequests |
        Group-Object { $_['ClientIp'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $pageClientSummary = @(
        $pageRequests |
        Group-Object { $_['UriStem'] } |
        Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
        Select-Object -First $TopCount
    )

    $dailySummary = @(
        $requests |
        Group-Object { $_['RequestDate'] } |
        Sort-Object Name |
        Select-Object -First 200
    )

    $reportLines = @()
    $reportLines += '# Web Traffic Report'
    $reportLines += ''
    $reportLines += ('- Log folder: `' + $LogFolder + '`')
    $reportLines += ('- Log files processed: ' + $logFiles.Count)
    $reportLines += ('- Total requests: ' + $requests.Count)
    $reportLines += ('- Successful or redirected requests: ' + $successfulRequests.Count)
    $reportLines += ('- Successful page requests: ' + $pageRequests.Count)
    $reportLines += ('- Error requests: ' + $errorRequests.Count)
    $reportLines += ('- Unique resources: ' + (@($requests | ForEach-Object { $_['UriStem'] } | Sort-Object -Unique).Count))
    $reportLines += ('- Unique client IPs: ' + (@($requests | ForEach-Object { $_['ClientIp'] } | Sort-Object -Unique).Count))
    if ($firstRequest.Count -gt 0) {
        $reportLines += ('- First request: ' + $firstRequest[0]['RequestDate'] + ' ' + $firstRequest[0]['RequestTime'])
    }
    if ($lastRequest.Count -gt 0) {
        $reportLines += ('- Last request: ' + $lastRequest[0]['RequestDate'] + ' ' + $lastRequest[0]['RequestTime'])
    }
    $reportLines += ''

    $reportLines += '## Top Application Paths'
    $reportLines += ''
    if ($topApplications.Count -eq 0) {
        $reportLines += '- No application path requests found.'
    }
    else {
        $applicationRows = @()
        foreach ($item in $topApplications) {
            $applicationRows += ,@($item.Name, $item.Count)
        }
        $reportLines += Get-MarkdownTableLines -Headers @('Application Path', 'Requests') -Rows $applicationRows
    }
    $reportLines += ''

    $reportLines += '## Top Requested Resources'
    $reportLines += ''
    if ($topResources.Count -eq 0) {
        $reportLines += '- No resource requests found.'
    }
    else {
        $resourceRows = @()
        foreach ($item in $topResources) {
            $resourceRows += ,@($item.Name, $item.Count)
        }
        $reportLines += Get-MarkdownTableLines -Headers @('Resource', 'Requests') -Rows $resourceRows
    }
    $reportLines += ''

    $reportLines += '## Top Requested Pages'
    $reportLines += ''
    if ($topPages.Count -eq 0) {
        $reportLines += '- No page requests found.'
    }
    else {
        $pageRows = @()
        foreach ($item in $topPages) {
            $pageRows += ,@($item.Name, $item.Count)
        }
        $reportLines += Get-MarkdownTableLines -Headers @('Page', 'Requests') -Rows $pageRows
    }
    $reportLines += ''

    $reportLines += '## Top Error Resources'
    $reportLines += ''
    if ($topErrors.Count -eq 0) {
        $reportLines += '- No error requests found.'
    }
    else {
        $errorRows = @()
        foreach ($item in $topErrors) {
            $errorRows += ,@($item.Name, $item.Count)
        }
        $reportLines += Get-MarkdownTableLines -Headers @('Resource', 'Error Requests') -Rows $errorRows
    }
    $reportLines += ''

    $reportLines += '## HTTP Status Codes'
    $reportLines += ''
    $statusRows = @()
    foreach ($item in $statusSummary) {
        $statusRows += ,@($item.Name, $item.Count)
    }
    $reportLines += Get-MarkdownTableLines -Headers @('Status Code', 'Requests') -Rows $statusRows
    $reportLines += ''

    $reportLines += '## HTTP Methods'
    $reportLines += ''
    $methodRows = @()
    foreach ($item in $methodSummary) {
        $methodRows += ,@($item.Name, $item.Count)
    }
    $reportLines += Get-MarkdownTableLines -Headers @('Method', 'Requests') -Rows $methodRows
    $reportLines += ''

    $reportLines += '## Top Client IP Addresses'
    $reportLines += ''
    $clientRows = @()
    foreach ($item in $clientSummary) {
        $clientRows += ,@($item.Name, $item.Count)
    }
    $reportLines += Get-MarkdownTableLines -Headers @('Client IP', 'Successful Requests') -Rows $clientRows
    $reportLines += ''

    $reportLines += '## Client IP Address To Pages Requested'
    $reportLines += ''
    if ($clientPageSummary.Count -eq 0) {
        $reportLines += '- No page requests found.'
    }
    else {
        foreach ($clientGroup in $clientPageSummary) {
            $reportLines += ('### `' + $clientGroup.Name + '`')
            $reportLines += ''

            $clientPageRows = @()
            $topClientPages = @(
                $clientGroup.Group |
                Group-Object { $_['UriStem'] } |
                Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
                Select-Object -First $TopCount
            )

            foreach ($pageGroup in $topClientPages) {
                $clientPageRows += ,@($pageGroup.Name, $pageGroup.Count)
            }

            $reportLines += Get-MarkdownTableLines -Headers @('Page', 'Requests From IP') -Rows $clientPageRows
            $reportLines += ''
        }
    }

    $reportLines += '## Page Requested By IP Addresses'
    $reportLines += ''
    if ($pageClientSummary.Count -eq 0) {
        $reportLines += '- No page requests found.'
    }
    else {
        foreach ($pageGroup in $pageClientSummary) {
            $reportLines += ('### `' + $pageGroup.Name + '`')
            $reportLines += ''

            $pageClientRows = @()
            $topPageClients = @(
                $pageGroup.Group |
                Group-Object { $_['ClientIp'] } |
                Sort-Object @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
                Select-Object -First $TopCount
            )

            foreach ($clientGroup in $topPageClients) {
                $pageClientRows += ,@($clientGroup.Name, $clientGroup.Count)
            }

            $reportLines += Get-MarkdownTableLines -Headers @('Client IP', 'Requests For Page') -Rows $pageClientRows
            $reportLines += ''
        }
    }

    $reportLines += '## Daily Request Counts'
    $reportLines += ''
    $dailyRows = @()
    foreach ($item in $dailySummary) {
        $dailyRows += ,@($item.Name, $item.Count)
    }
    $reportLines += Get-MarkdownTableLines -Headers @('Date', 'Requests') -Rows $dailyRows
    $reportLines += ''

    Set-Content -LiteralPath $OutputPath -Value $reportLines -Encoding UTF8

    Write-Host ('Markdown report created: ' + $OutputPath)
}
catch {
    $lineNumber = $_.InvocationInfo.ScriptLineNumber
    Write-Error ('Line ' + $lineNumber + ': ' + $_.Exception.Message)
    exit 1
}
