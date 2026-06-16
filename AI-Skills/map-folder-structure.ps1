param(
    # Root folder that will be scanned.
    [Parameter(Mandatory = $true)]
    [string]$RootFolder,

    # Optional path for the JSON application map.
    [Parameter(Mandatory = $false)]
    [string]$JsonOutputPath,

    # Optional path for the markdown document.
    [Parameter(Mandatory = $false)]
    [string]$MarkdownOutputPath
)

$ErrorActionPreference = 'Stop'

function Test-IsBlank {
    param(
        [string]$Value
    )

    return ($null -eq $Value -or $Value -match '^\s*$')
}

function Test-IsExcludedDevelopmentFolder {
    param(
        [string]$FolderName
    )

    return ($FolderName -like '.*')
}

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseFullPath = (Resolve-Path -LiteralPath $BasePath).Path
    $targetFullPath = (Resolve-Path -LiteralPath $TargetPath).Path
    $baseFullPath = $baseFullPath.TrimEnd('\')

    if ($targetFullPath -eq $baseFullPath) {
        return '.'
    }

    $prefix = $baseFullPath + '\'
    if ($targetFullPath.Length -ge $prefix.Length) {
        $leftSide = $targetFullPath.Substring(0, $prefix.Length)
        if ($leftSide.ToLower() -eq $prefix.ToLower()) {
            return $targetFullPath.Substring($prefix.Length)
        }
    }

    return $targetFullPath
}

function New-FileMapItem {
    param(
        $File,
        [string]$RootPath
    )

    return @{
        Name         = $File.Name
        RelativePath = Get-RelativePath -BasePath $RootPath -TargetPath $File.FullName
        Extension    = $File.Extension
        SizeBytes    = $File.Length
    }
}

function New-FolderMapItem {
    param(
        [string]$FolderPath,
        [string]$RootPath,
        [string[]]$SkipFilePaths
    )

    $folder = Get-Item -LiteralPath $FolderPath
    $childFolders = @(
        Get-ChildItem -LiteralPath $folder.FullName -Directory |
        Where-Object { -not (Test-IsExcludedDevelopmentFolder -FolderName $_.Name) } |
        Sort-Object Name
    )
    $childFiles = @(
        Get-ChildItem -LiteralPath $folder.FullName -File |
        Where-Object { @($SkipFilePaths) -notcontains $_.FullName } |
        Sort-Object Name
    )

    $folderItems = @()
    foreach ($childFolder in $childFolders) {
        $folderItems += New-FolderMapItem -FolderPath $childFolder.FullName -RootPath $RootPath -SkipFilePaths $SkipFilePaths
    }

    $fileItems = @()
    foreach ($childFile in $childFiles) {
        $fileItems += New-FileMapItem -File $childFile -RootPath $RootPath
    }

    return @{
        Type         = 'Folder'
        Name         = $folder.Name
        RelativePath = Get-RelativePath -BasePath $RootPath -TargetPath $folder.FullName
        Folders      = $folderItems
        Files        = $fileItems
    }
}

function Get-MapCounts {
    param(
        $FolderNode
    )

    $folderCount = 1
    $fileCount = @($FolderNode.Files).Count

    foreach ($childFolder in @($FolderNode.Folders)) {
        $childCounts = Get-MapCounts -FolderNode $childFolder
        $folderCount = $folderCount + $childCounts.FolderCount
        $fileCount = $fileCount + $childCounts.FileCount
    }

    return @{
        FolderCount = $folderCount
        FileCount   = $fileCount
    }
}

function Get-MarkdownTreeLines {
    param(
        $FolderNode,
        [int]$Level
    )

    $lines = @()
    $folderIndent = '  ' * $Level
    $fileIndent = '  ' * ($Level + 1)

    if ($Level -eq 0) {
        $lines += '- `./`'
    }
    else {
        $lines += ($folderIndent + '- `' + $FolderNode.Name + '/`')
    }

    foreach ($childFolder in @($FolderNode.Folders)) {
        $lines += Get-MarkdownTreeLines -FolderNode $childFolder -Level ($Level + 1)
    }

    foreach ($file in @($FolderNode.Files)) {
        $lines += ($fileIndent + '- `' + $file.Name + '`')
    }

    return $lines
}

function Get-MarkdownFolderSections {
    param(
        $FolderNode
    )

    $lines = @()

    if ($FolderNode.RelativePath -eq '.') {
        $displayPath = './'
    }
    else {
        $displayPath = './' + ($FolderNode.RelativePath -replace '\\', '/')
    }

    $lines += ('### `' + $displayPath + '`')
    $lines += ''

    if (@($FolderNode.Files).Count -eq 0) {
        $lines += '- No files in this folder'
    }
    else {
        foreach ($file in @($FolderNode.Files)) {
            $lines += ('- `' + $file.Name + '` (' + $file.SizeBytes + ' bytes)')
        }
    }

    $lines += ''

    foreach ($childFolder in @($FolderNode.Folders)) {
        $lines += Get-MarkdownFolderSections -FolderNode $childFolder
    }

    return $lines
}

try {
    $rootFullPath = (Resolve-Path -LiteralPath $RootFolder).Path

    if (-not (Test-Path -LiteralPath $rootFullPath -PathType Container)) {
        throw "The root folder does not exist or is not a folder: $RootFolder"
    }

    if (Test-IsBlank -Value $JsonOutputPath) {
        $JsonOutputPath = Join-Path -Path $rootFullPath -ChildPath 'application-map.json'
    }

    if (Test-IsBlank -Value $MarkdownOutputPath) {
        $MarkdownOutputPath = Join-Path -Path $rootFullPath -ChildPath 'application-map.md'
    }

    $jsonOutputFolder = Split-Path -Path $JsonOutputPath -Parent
    if (-not (Test-IsBlank -Value $jsonOutputFolder) -and -not (Test-Path -LiteralPath $jsonOutputFolder)) {
        New-Item -Path $jsonOutputFolder -ItemType Directory -Force | Out-Null
    }

    $markdownOutputFolder = Split-Path -Path $MarkdownOutputPath -Parent
    if (-not (Test-IsBlank -Value $markdownOutputFolder) -and -not (Test-Path -LiteralPath $markdownOutputFolder)) {
        New-Item -Path $markdownOutputFolder -ItemType Directory -Force | Out-Null
    }

    $skipFilePaths = @()
    foreach ($candidatePath in @($JsonOutputPath, $MarkdownOutputPath)) {
        if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            $skipFilePaths += (Get-Item -LiteralPath $candidatePath).FullName
        }
    }

    # Step 1: Scan the folder and build the application map.
    $rootMap = New-FolderMapItem -FolderPath $rootFullPath -RootPath $rootFullPath -SkipFilePaths $skipFilePaths
    $counts = Get-MapCounts -FolderNode $rootMap

    $applicationMap = @{
        GeneratedOn = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        RootFolder  = $rootFullPath
        Summary     = @{
            TotalFolders = $counts.FolderCount
            TotalFiles   = $counts.FileCount
        }
        Structure   = $rootMap
    }

    # Step 2: Save the application map as JSON.
    $jsonContent = $applicationMap | ConvertTo-Json -Depth 100
    Set-Content -LiteralPath $JsonOutputPath -Value $jsonContent -Encoding UTF8

    # Step 3: Build markdown for documentation and point to the JSON file.

    $markdownLines = @()
    $markdownLines += '# Application Map'
    $markdownLines += ''
    $markdownLines += ('- Generated on: ' + $applicationMap.GeneratedOn)
    $markdownLines += ('- Root folder: `' + $applicationMap.RootFolder + '`')
    $markdownLines += ('- JSON source: `' + $JsonOutputPath + '`')
    $markdownLines += ''
    $markdownLines += '## Summary'
    $markdownLines += ''
    $markdownLines += ('- Total folders: ' + $applicationMap.Summary.TotalFolders)
    $markdownLines += ('- Total files: ' + $applicationMap.Summary.TotalFiles)
    $markdownLines += ''
    $markdownLines += '## Folder Structure'
    $markdownLines += ''
    $markdownLines += Get-MarkdownTreeLines -FolderNode $applicationMap.Structure -Level 0
    $markdownLines += ''
    $markdownLines += '## Files By Folder'
    $markdownLines += ''
    $markdownLines += Get-MarkdownFolderSections -FolderNode $applicationMap.Structure
    $markdownLines += '## JSON Source'
    $markdownLines += ''
    $markdownLines += ('- See `' + $JsonOutputPath + '` for the full JSON application map.')

    Set-Content -LiteralPath $MarkdownOutputPath -Value $markdownLines -Encoding UTF8

    Write-Host ('JSON map created: ' + $JsonOutputPath)
    Write-Host ('Markdown map created: ' + $MarkdownOutputPath)
}
catch {
    $lineNumber = $_.InvocationInfo.ScriptLineNumber
    Write-Error ('Line ' + $lineNumber + ': ' + $_.Exception.Message)
    exit 1
}