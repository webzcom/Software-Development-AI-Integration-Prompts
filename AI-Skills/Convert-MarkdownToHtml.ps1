[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Escape-Html {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Text
    )

    if ($null -eq $Text) {
        return ''
    }

    $escapedText = $Text -replace '&', '&amp;'
    $escapedText = $escapedText -replace '<', '&lt;'
    $escapedText = $escapedText -replace '>', '&gt;'
    $escapedText = $escapedText -replace '"', '&quot;'

    return $escapedText
}

function Get-MarkdownTitle {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$FallbackTitle
    )

    foreach ($line in ($Content -split "`r?`n")) {
        if ($line -match '^#\s+(.+?)\s*$') {
            return $Matches[1].Trim()
        }
    }

    return $FallbackTitle
}

function Normalize-PathInput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )

    $normalizedPath = ($InputPath -replace '^\s+|\s+$', '')
    $previousPath = $null

    while ($normalizedPath -ne $previousPath) {
        $previousPath = $normalizedPath
        $normalizedPath = ($normalizedPath -replace '^\s*"(.*)"\s*$', '$1')
        $normalizedPath = ($normalizedPath -replace "^\s*'(.*)'\s*$", '$1')
        $normalizedPath = ($normalizedPath -replace '^\s+|\s+$', '')
    }

    return $normalizedPath
}

function Convert-InlineMarkdown {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Text
    )

    $result = Escape-Html -Text $Text
    $result = $result -replace '!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]+)")?\)', '<img alt="$1" src="$2" />'
    $result = $result -replace '\[([^\]]+)\]\(([^)\s]+)(?:\s+"([^"]+)")?\)', '<a href="$2">$1</a>'
    $result = $result -replace '`([^`]+)`', '<code>$1</code>'
    $result = $result -replace '\*\*([^*]+)\*\*', '<strong>$1</strong>'
    $result = $result -replace '__([^_]+)__', '<strong>$1</strong>'
    $result = $result -replace '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>'
    $result = $result -replace '(?<!_)_([^_]+)_(?!_)', '<em>$1</em>'
    $result = $result -replace '~~([^~]+)~~', '<del>$1</del>'

    return $result
}

function Convert-ParagraphToHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    if ($Lines.Count -eq 0) {
        return $null
    }

    $parts = @()
    foreach ($line in $Lines) {
        $parts += ($line -replace '^\s+|\s+$', '')
    }

    return '<p>{0}</p>' -f (Convert-InlineMarkdown -Text ($parts -join ' '))
}

function Convert-ListToHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Items,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ul', 'ol')]
        [string]$ListTag
    )

    if ($Items.Count -eq 0) {
        return $null
    }

    $output = @("<$ListTag>")
    foreach ($item in $Items) {
        $output += ('    <li>{0}</li>' -f (Convert-InlineMarkdown -Text ($item -replace '^\s+|\s+$', '')))
    }
    $output += "</$ListTag>"

    return ($output -join "`n")
}

function Get-MarkdownTableCells {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    $trimmedLine = $Line -replace '^\s*\|', ''
    $trimmedLine = $trimmedLine -replace '\|\s*$', ''

    if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
        return @()
    }

    $cells = @()
    foreach ($cell in ($trimmedLine -split '\|')) {
        $cells += ($cell -replace '^\s+|\s+$', '')
    }

    return $cells
}

function Test-MarkdownTableSeparator {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    $cells = Get-MarkdownTableCells -Line $Line
    if ($cells.Count -eq 0) {
        return $false
    }

    foreach ($cell in $cells) {
        if ($cell -notmatch '^:?-{3,}:?$') {
            return $false
        }
    }

    return $true
}

function Convert-MarkdownTableToHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Header,

        [Parameter(Mandatory = $true)]
        [object[]]$Rows
    )

    if ($Header.Count -eq 0) {
        return $null
    }

    $output = @(
        '<table>',
        '    <thead>',
        '        <tr>'
    )

    foreach ($cell in $Header) {
        $output += ('            <th>{0}</th>' -f (Convert-InlineMarkdown -Text $cell))
    }

    $output += @(
        '        </tr>',
        '    </thead>',
        '    <tbody>'
    )

    foreach ($row in $Rows) {
        $output += '        <tr>'
        foreach ($cell in $row) {
            $output += ('            <td>{0}</td>' -f (Convert-InlineMarkdown -Text $cell))
        }
        $output += '        </tr>'
    }

    $output += @(
        '    </tbody>',
        '</table>'
    )

    return ($output -join "`n")
}

function Convert-CodeBlockToHtml {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $false)]
        [string]$Language
    )

    $languageClass = ''
    if (-not [string]::IsNullOrWhiteSpace($Language)) {
        $languageClass = ' class="language-{0}"' -f ($Language -replace '[^A-Za-z0-9_-]', '')
    }

    return '<pre><code{0}>{1}</code></pre>' -f $languageClass, (Escape-Html -Text ($Lines -join "`n"))
}

function Convert-MarkdownContentToHtml {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Markdown
    )

    $lines = $Markdown -split "`r?`n"
    $htmlBlocks = @()
    $paragraphLines = @()
    $listType = $null
    $listItems = @()
    $quoteLines = @()
    $inCodeBlock = $false
    $codeLanguage = ''
    $codeLines = @()

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]

        if ($inCodeBlock) {
            if ($line -match '^\s*```\s*$') {
                $htmlBlocks += Convert-CodeBlockToHtml -Lines $codeLines -Language $codeLanguage
                $inCodeBlock = $false
                $codeLanguage = ''
                $codeLines = @()
            }
            else {
                $codeLines += $line
            }

            continue
        }

        if ($line -match '^\s*```\s*([A-Za-z0-9#+._-]+)?\s*$') {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0) {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
                $listType = $null
            }
            if ($quoteLines.Count -gt 0) {
                $htmlBlocks += "<blockquote>`n$(Convert-MarkdownContentToHtml -Markdown ($quoteLines -join "`n"))`n</blockquote>"
                $quoteLines = @()
            }

            $inCodeBlock = $true
            $codeLanguage = $Matches[1]
            $codeLines = @()
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0) {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
                $listType = $null
            }
            if ($quoteLines.Count -gt 0) {
                $htmlBlocks += "<blockquote>`n$(Convert-MarkdownContentToHtml -Markdown ($quoteLines -join "`n"))`n</blockquote>"
                $quoteLines = @()
            }
            continue
        }

        if ($line -match '^\s*>\s?(.*)$') {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0) {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
                $listType = $null
            }

            $quoteLines += $Matches[1]
            continue
        }
        elseif ($quoteLines.Count -gt 0) {
            $htmlBlocks += "<blockquote>`n$(Convert-MarkdownContentToHtml -Markdown ($quoteLines -join "`n"))`n</blockquote>"
            $quoteLines = @()
        }

        if (
            $line -match '\|' -and
            ($index + 1) -lt $lines.Count -and
            (Test-MarkdownTableSeparator -Line $lines[$index + 1])
        ) {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0) {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
                $listType = $null
            }

            $headerCells = Get-MarkdownTableCells -Line $line
            $tableRows = @()
            $index++

            while (($index + 1) -lt $lines.Count) {
                $nextLine = $lines[$index + 1]

                if ([string]::IsNullOrWhiteSpace($nextLine)) {
                    break
                }
                if ($nextLine -notmatch '\|') {
                    break
                }
                if ($nextLine -match '^\s*#' -or $nextLine -match '^\s*>') {
                    break
                }
                if ($nextLine -match '^\s*[-*+]\s+' -or $nextLine -match '^\s*\d+\.\s+') {
                    break
                }

                $tableRows += ,(Get-MarkdownTableCells -Line $nextLine)
                $index++
            }

            $htmlBlocks += Convert-MarkdownTableToHtml -Header $headerCells -Rows $tableRows
            continue
        }

        if ($line -match '^\s*(#{1,6})\s+(.+?)\s*$') {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0) {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
                $listType = $null
            }

            $headingLevel = $Matches[1].Length
            $headingText = Convert-InlineMarkdown -Text $Matches[2]
            $htmlBlocks += "<h$headingLevel>$headingText</h$headingLevel>"
            continue
        }

        if ($line -match '^\s*((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$') {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0) {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
                $listType = $null
            }

            $htmlBlocks += '<hr />'
            continue
        }

        if ($line -match '^\s*[-*+]\s+(.+)$') {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0 -and $listType -ne 'ul') {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
            }

            $listType = 'ul'
            $listItems += $Matches[1]
            continue
        }

        if ($line -match '^\s*\d+\.\s+(.+)$') {
            if ($paragraphLines.Count -gt 0) {
                $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
                $paragraphLines = @()
            }
            if ($listItems.Count -gt 0 -and $listType -ne 'ol') {
                $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
                $listItems = @()
            }

            $listType = 'ol'
            $listItems += $Matches[1]
            continue
        }
        elseif ($listItems.Count -gt 0) {
            $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
            $listItems = @()
            $listType = $null
        }

        $paragraphLines += $line
    }

    if ($inCodeBlock) {
        $htmlBlocks += Convert-CodeBlockToHtml -Lines $codeLines -Language $codeLanguage
    }
    if ($paragraphLines.Count -gt 0) {
        $htmlBlocks += Convert-ParagraphToHtml -Lines $paragraphLines
    }
    if ($listItems.Count -gt 0) {
        $htmlBlocks += Convert-ListToHtml -Items $listItems -ListTag $listType
    }
    if ($quoteLines.Count -gt 0) {
        $htmlBlocks += "<blockquote>`n$(Convert-MarkdownContentToHtml -Markdown ($quoteLines -join "`n"))`n</blockquote>"
    }

    return ($htmlBlocks -join "`n")
}

function Convert-MarkdownFileToHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MarkdownPath
    )

    if (-not (Test-Path -LiteralPath $MarkdownPath -PathType Leaf)) {
        throw "File not found: $MarkdownPath"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $MarkdownPath).Path
    $markdownContent = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8
    $fileInfo = Get-Item -LiteralPath $resolvedPath
    $pageTitle = Get-MarkdownTitle -Content $markdownContent -FallbackTitle $fileInfo.BaseName
    $encodedTitle = Escape-Html -Text $pageTitle
    $encodedSourceName = Escape-Html -Text $fileInfo.Name
    $contentHtml = Convert-MarkdownContentToHtml -Markdown $markdownContent

    $htmlDocument = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="color-scheme" content="light dark" />
    <title>$encodedTitle</title>
    <style>
        :root {
            --bg: #0b1020;
            --bg-accent: rgba(255, 255, 255, 0.06);
            --card: rgba(15, 23, 42, 0.72);
            --text: #e5eefb;
            --muted: #a7b4c8;
            --line: rgba(148, 163, 184, 0.25);
            --primary: #7dd3fc;
            --primary-strong: #38bdf8;
            --code-bg: rgba(2, 6, 23, 0.82);
            --quote-bg: rgba(125, 211, 252, 0.08);
            --shadow: 0 20px 45px rgba(0, 0, 0, 0.35);
        }

        body.light {
            --bg: linear-gradient(180deg, #f8fafc 0%, #e2e8f0 100%);
            --bg-accent: rgba(15, 23, 42, 0.04);
            --card: rgba(255, 255, 255, 0.92);
            --text: #0f172a;
            --muted: #475569;
            --line: rgba(51, 65, 85, 0.16);
            --primary: #0284c7;
            --primary-strong: #0369a1;
            --code-bg: #0f172a;
            --quote-bg: rgba(2, 132, 199, 0.08);
            --shadow: 0 20px 45px rgba(15, 23, 42, 0.12);
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            margin: 0;
            min-height: 100vh;
            background: radial-gradient(circle at top, #1e293b 0%, #0b1020 45%, #020617 100%);
            color: var(--text);
            font-family: Inter, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.7;
            transition: background 0.25s ease, color 0.25s ease;
        }

        body.light {
            background: var(--bg);
        }

        .page-shell {
            max-width: 1100px;
            margin: 0 auto;
            padding: 32px 20px 72px;
        }

        .hero {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            margin-bottom: 24px;
            padding: 24px 28px;
            background: var(--bg-accent);
            border: 1px solid var(--line);
            border-radius: 24px;
            backdrop-filter: blur(12px);
            box-shadow: var(--shadow);
        }

        .hero h1 {
            margin: 0;
            font-size: clamp(1.8rem, 4vw, 3rem);
            line-height: 1.15;
            letter-spacing: -0.03em;
        }

        .hero p {
            margin: 8px 0 0;
            color: var(--muted);
        }

        .toolbar {
            display: flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
        }

        button.theme-toggle {
            border: 1px solid var(--line);
            background: var(--card);
            color: var(--text);
            padding: 10px 14px;
            border-radius: 999px;
            cursor: pointer;
            font: inherit;
            transition: transform 0.2s ease, border-color 0.2s ease, background 0.2s ease;
        }

        button.theme-toggle:hover {
            transform: translateY(-1px);
            border-color: var(--primary);
        }

        main.content {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 24px;
            padding: clamp(20px, 3vw, 40px);
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        main.content > :first-child {
            margin-top: 0;
        }

        main.content > :last-child {
            margin-bottom: 0;
        }

        h1, h2, h3, h4, h5, h6 {
            line-height: 1.25;
            letter-spacing: -0.02em;
            margin-top: 1.8em;
            margin-bottom: 0.7em;
        }

        h1 { font-size: clamp(2rem, 4vw, 2.9rem); }
        h2 { font-size: clamp(1.55rem, 3vw, 2.1rem); }
        h3 { font-size: clamp(1.25rem, 2vw, 1.6rem); }

        p, ul, ol {
            margin: 1em 0;
        }

        a {
            color: var(--primary);
            text-decoration-thickness: 0.08em;
            text-underline-offset: 0.15em;
        }

        a:hover {
            color: var(--primary-strong);
        }

        hr {
            border: 0;
            border-top: 1px solid var(--line);
            margin: 2rem 0;
        }

        blockquote {
            margin: 1.5rem 0;
            padding: 0.2rem 1rem;
            border-left: 4px solid var(--primary);
            background: var(--quote-bg);
            border-radius: 0 12px 12px 0;
            color: var(--muted);
        }

        code {
            font-family: Cascadia Code, Consolas, Monaco, monospace;
            font-size: 0.95em;
            background: rgba(148, 163, 184, 0.12);
            padding: 0.18em 0.4em;
            border-radius: 6px;
        }

        pre {
            background: var(--code-bg);
            color: #e2e8f0;
            padding: 18px;
            border-radius: 16px;
            overflow-x: auto;
            border: 1px solid rgba(148, 163, 184, 0.18);
        }

        pre code {
            background: transparent;
            padding: 0;
            border-radius: 0;
            color: inherit;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.5rem 0;
            display: block;
            overflow-x: auto;
        }

        th, td {
            border: 1px solid var(--line);
            padding: 12px 14px;
            text-align: left;
            vertical-align: top;
        }

        th {
            background: rgba(148, 163, 184, 0.08);
        }

        img {
            max-width: 100%;
            height: auto;
            border-radius: 16px;
        }

        ul li::marker,
        ol li::marker {
            color: var(--primary);
        }

        .footer {
            margin-top: 18px;
            text-align: center;
            color: var(--muted);
            font-size: 0.95rem;
        }

        @media (max-width: 720px) {
            .hero {
                flex-direction: column;
                align-items: flex-start;
            }
        }
    </style>
</head>
<body>
    <div class="page-shell">
        <header class="hero">
            <div>
                <h1>$encodedTitle</h1>
                <p>Generated from Markdown with PowerShell</p>
            </div>
            <div class="toolbar">
                <button class="theme-toggle" type="button" id="themeToggle" aria-label="Toggle color theme">Toggle theme</button>
            </div>
        </header>

        <main class="content">
$contentHtml
        </main>

        <div class="footer">
            Source: $encodedSourceName
        </div>
    </div>

    <script>
        (function () {
            const storageKey = 'markdown-html-theme';
            const savedTheme = localStorage.getItem(storageKey);
            if (savedTheme === 'light') {
                document.body.classList.add('light');
            }

            const toggleButton = document.getElementById('themeToggle');
            toggleButton.addEventListener('click', function () {
                document.body.classList.toggle('light');
                localStorage.setItem(storageKey, document.body.classList.contains('light') ? 'light' : 'dark');
            });
        }());
    </script>
</body>
</html>
"@

    $outputPath = Join-Path -Path $fileInfo.DirectoryName -ChildPath ($fileInfo.BaseName + '.HTML')
    Set-Content -LiteralPath $outputPath -Value $htmlDocument -Encoding UTF8

    return $outputPath
}

try {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Read-Host 'Enter the path to the Markdown file'
    }

    $Path = Normalize-PathInput -InputPath $Path

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'No file path was provided.'
    }

    $outputFile = Convert-MarkdownFileToHtml -MarkdownPath $Path
    Write-Host "HTML file created: $outputFile" -ForegroundColor Green
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
