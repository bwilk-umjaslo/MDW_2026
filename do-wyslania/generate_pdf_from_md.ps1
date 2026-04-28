$inputFile = Join-Path $PSScriptRoot 'koncepcja-tresci-miedzynarodowe-dni-wina-jaslo.md'
$outputFile = Join-Path $PSScriptRoot 'koncepcja-tresci-miedzynarodowe-dni-wina-jaslo.pdf'

$lines = Get-Content -Path $inputFile -Encoding UTF8

function Escape-PdfText($text) {
    return $text -replace '\\', '\\\\' -replace '\(', '\\(' -replace '\)', '\\)'
}

$encoder = [System.Text.Encoding]::ASCII
$output = New-Object System.Collections.ArrayList
$offsets = @()

function AppendText($text) {
    $bytes = $encoder.GetBytes($text)
    $output.AddRange($bytes)
}

function AddObject($content) {
    $offsets += $output.Count
    AppendText($content)
    AppendText("endobj`n")
}

function AddStreamObject($header, $streamContent) {
    $offsets += $output.Count
    $streamBytes = $encoder.GetBytes($streamContent)
    AppendText($header)
    AppendText("/Length $($streamBytes.Length)`nstream`n")
    $output.AddRange($streamBytes)
    AppendText("`nendstream`nendobj`n")
}

# Build pages from markdown lines
$pages = @()
$currentPage = @()
$y = 780
$topMargin = 780
$bottomMargin = 60
foreach ($rawLine in $lines) {
    $line = $rawLine.TrimEnd()
    if ($line -eq '') {
        $currentPage += ''
        $y -= 10
        continue
    }
    $fontSize = 11
    $step = 14
    if ($line.StartsWith('# ')) { $fontSize = 18; $step = 24; $line = $line.Substring(2).Trim() }
    elseif ($line.StartsWith('## ')) { $fontSize = 14; $step = 20; $line = $line.Substring(3).Trim() }
    elseif ($line.StartsWith('### ')) { $fontSize = 12; $step = 18; $line = $line.Substring(4).Trim() }
    if ($y - $step - $bottomMargin - 10 -lt 0) {
        $pages += ,$currentPage
        $currentPage = @()
        $y = $topMargin
    }
    $currentPage += [PSCustomObject]@{ Text=$line; Size=$fontSize; Step=$step }
    $y -= $step
}
if ($currentPage.Count -gt 0) { $pages += ,$currentPage }
if ($pages.Count -eq 0) { $pages += ,(@()) }

# Build PDF
AppendText("%PDF-1.4`n")
AddObject("1 0 obj`n<< /Type /Catalog /Pages 2 0 R >>`n")

$pageRefs = @()
$refIndex = 3
foreach ($page in $pages) {
    $pageRefs += "$refIndex 0 R"
    $refIndex += 2
}
$kids = $pageRefs -join ' '
AddObject("2 0 obj`n<< /Type /Pages /Kids [$kids] /Count $($pages.Count) >>`n")

$objectIndex = 3
foreach ($page in $pages) {
    $contentStream = ''
    $yPos = 780
    foreach ($item in $page) {
        if ($item -eq '') {
            $yPos -= 10
            continue
        }
        $text = Escape-PdfText($item.Text)
        switch ($item.Size) {
            18 { $contentStream += "BT /F2 18 Tf 50 $yPos Td ($text) Tj ET`n" }
            14 { $contentStream += "BT /F2 14 Tf 50 $yPos Td ($text) Tj ET`n" }
            12 { $contentStream += "BT /F2 12 Tf 50 $yPos Td ($text) Tj ET`n" }
            default { $contentStream += "BT /F1 11 Tf 50 $yPos Td ($text) Tj ET`n" }
        }
        $yPos -= $item.Step
    }
    $contentStream += "BT /F1 10 Tf 270 20 Td ($([int]($pages.IndexOf($page) + 1))) Tj ET`n"

    $contentRef = "$objectIndex 0 R"
    AddStreamObject("$contentRef`n<< ", $contentStream)
    $objectIndex++
    AddObject("$objectIndex 0 obj`n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 11 0 R /F2 12 0 R >> >> /Contents $contentRef >>`n")
    $objectIndex++
}

AddObject("11 0 obj`n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>`n")
AddObject("12 0 obj`n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>`n")

$xrefOffset = $output.Count
AppendText("xref`n0 $objectIndex`n0000000000 65535 f `n")
foreach ($offset in $offsets) {
    AppendText(("{0:D10} 00000 n `n" -f $offset))
}
AppendText("trailer`n<< /Size $objectIndex /Root 1 0 R >>`nstartxref`n$xrefOffset`n%%EOF`n")

[System.IO.File]::WriteAllBytes($outputFile, $output.ToArray())
Write-Output "PDF wygenerowany: $outputFile"
