# WordPress Import Generator - MDW 2026 - FIXED VERSION

$ArticlesDir = "docs\artykuly"
$OutputDir = (Get-Location).Path

Write-Host "============================================================"
Write-Host "WordPress Import Generator - MDW 2026"
Write-Host "============================================================"
Write-Host ""

# Find all articles
$mdFiles = @(Get-ChildItem -Path $ArticlesDir -Recurse -Include "*.md" | Where-Object {$_.Name -ne "index.md"} | Sort-Object FullName)
Write-Host "Found $($mdFiles.Count) articles"
Write-Host ""

# Publication schedule setup
$articles = @()
$startDate = [DateTime]::Parse('2026-05-12')  # Tuesday
$pubDayWeekly = @(1, 3, 5)  # Tuesday, Thursday, Saturday

# Process each article
for ($i = 0; $i -lt $mdFiles.Count; $i++) {
    $file = $mdFiles[$i]
    $filename = $file.Name
    
    # Get category from path
    $category = "Inne"
    if ($file.FullName -like "*wydarzenie*") { $category = "Wydarzenie" }
    elseif ($file.FullName -like "*uczestnik*") { $category = "Uczestnik i degustacja" }
    elseif ($file.FullName -like "*polskie*") { $category = "Polskie winiarstwo" }
    elseif ($file.FullName -like "*enoturystyka*") { $category = "Enoturystyka" }
    elseif ($file.FullName -like "*jaslo*") { $category = "Jaslo i region" }
    
    # Calculate publication date
    $dayInCycle = $i % 3
    $weekOffset = [int]($i / 3)
    $pubDate = $startDate.AddDays($weekOffset * 7)
    $dayOfWeekNeeded = $pubDayWeekly[$dayInCycle]
    $dayOfWeekCurrent = [int]$pubDate.DayOfWeek
    $daysToAdd = $dayOfWeekNeeded - $dayOfWeekCurrent
    if ($daysToAdd -lt 0) { $daysToAdd += 7 }
    $pubDate = $pubDate.AddDays($daysToAdd)
    
    # Read file content
    $fullContent = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    
    # Parse frontmatter and body
    $lines = $fullContent -split "`n"
    $inFrontmatter = $false
    $fmLines = @()
    $bodyLines = @()
    $fmFinished = $false
    
    for ($lineIdx = 0; $lineIdx -lt $lines.Count; $lineIdx++) {
        $line = $lines[$lineIdx]
        
        if ($lineIdx -eq 0 -and $line -match "^---") {
            $inFrontmatter = $true
            continue
        }
        
        if ($inFrontmatter -and $line -match "^---") {
            $fmFinished = $true
            $inFrontmatter = $false
            continue
        }
        
        if ($inFrontmatter) {
            $fmLines += $line
        } elseif ($fmFinished) {
            $bodyLines += $line
        }
    }
    
    # Extract frontmatter values
    $title = "Bez tytulu"
    $description = ""
    foreach ($line in $fmLines) {
        if ($line -match '^title:\s*"([^"]+)"') {
            $title = $matches[1]
        } elseif ($line -match "^title:\s*'([^']+)'") {
            $title = $matches[1]
        } elseif ($line -match '^description:\s*"([^"]+)"') {
            $description = $matches[1]
        } elseif ($line -match "^description:\s*'([^']+)'") {
            $description = $matches[1]
        }
    }
    
    # Join body and clean
    $body = $bodyLines -join "`n"
    
    # Remove unwanted sections
    $body = $body -replace "(?ms)^##\s+Komentarz dla recenzentki.*?(?=^##|\Z)", ""
    $body = $body -replace "(?ms)^##\s+Komentarz autora.*?(?=^##|\Z)", ""
    $body = $body -replace "(?ms)^##\s+Uwagi do tego materialu.*?(?=^##|\Z)", ""
    $body = $body -replace "\[.*?\]\(https://docs\.google\.com/forms/.*?\)", ""
    $body = $body -replace "`n`n`n+", "`n`n"
    $body = $body.Trim()
    
    # Generate slug from filename
    $slug = $filename -replace '\.md$', '' -replace 'index', '' -replace '^-+', '' -replace '-+$', ''
    if (-not $slug) { $slug = "article" }
    
    # Generate SEO data
    $titleLower = $title.ToLower()
    if ($titleLower -match "mdw|miedzy") {
        $focusKeyword = "Miedzynarodowe Dni Wina w Jasle"
    } elseif ($titleLower -match "wino") {
        $focusKeyword = "polskie wino"
    } else {
        $focusKeyword = "wino"
    }
    
    # Meta title (max 60 chars)
    $metaTitle = if ($title.Length -lt 35) { 
        "$title - Miedzynarodowe Dni Wina w Jasle" 
    } else { 
        ($title.Substring(0, 35) + "... - Miedzynarodowe Dni Wina w Jasle").Substring(0, 60) 
    }
    
    # Meta description (140-155 chars)
    $metaDesc = if ($description) { $description } else { $title }
    if ($metaDesc -notmatch "wino") { $metaDesc += " Artykul z Miedzynarodowych Dni Wina." }
    if ($metaDesc.Length -gt 155) { $metaDesc = $metaDesc.Substring(0, 152) + "..." }
    
    # Tags
    $tags = @($category, "wino", "MDW")
    if ($titleLower -match "degust|uczestnik") { $tags += "degustacja" }
    if ($titleLower -match "polskie") { $tags += "Polskie winiarstwo" }
    if ($titleLower -match "turyst") { $tags += "enoturystyka" }
    if ($titleLower -match "jaslo") { $tags += "Jaslo" }
    
    $tags = $tags | Select-Object -Unique | Select-Object -First 5
    
    $article = [PSCustomObject]@{
        Title = $title
        Slug = $slug
        Content = $body
        Excerpt = $description
        Date = $pubDate
        Category = $category
        SEOTitle = $metaTitle
        SEODescription = $metaDesc
        FocusKeyword = $focusKeyword
        Tags = $tags
    }
    
    $articles += $article
}

Write-Host "Processed $($articles.Count) articles"
Write-Host ""

# Build XML
$xmlBuilder = [System.Text.StringBuilder]::new()
$null = $xmlBuilder.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
$null = $xmlBuilder.AppendLine('<rss version="2.0"')
$null = $xmlBuilder.AppendLine('    xmlns:excerpt="http://wordpress.org/export/1.2/excerpt/"')
$null = $xmlBuilder.AppendLine('    xmlns:content="http://purl.org/rss/1.0/modules/content/"')
$null = $xmlBuilder.AppendLine('    xmlns:dc="http://purl.org/dc/elements/1.1/"')
$null = $xmlBuilder.AppendLine('    xmlns:wp="http://wordpress.org/export/1.2/">')
$null = $xmlBuilder.AppendLine('    <channel>')
$null = $xmlBuilder.AppendLine('        <title>MDW 2026 Import</title>')
$null = $xmlBuilder.AppendLine('        <link>https://example.com</link>')
$null = $xmlBuilder.AppendLine('        <description>MDW 2026 Articles</description>')
$null = $xmlBuilder.AppendLine('        <wp:wxr_version>1.2</wp:wxr_version>')
$null = $xmlBuilder.AppendLine('        <wp:base_site_url>https://example.com</wp:base_site_url>')
$null = $xmlBuilder.AppendLine('        <wp:base_blog_url>https://example.com</wp:base_blog_url>')

foreach ($i in 0..($articles.Count - 1)) {
    $article = $articles[$i]
    $postId = $i + 1
    
    $null = $xmlBuilder.AppendLine('        <item>')
    $null = $xmlBuilder.AppendLine("            <title>$($article.Title)</title>")
    $null = $xmlBuilder.AppendLine("            <link>https://example.com/$($article.Slug)/</link>")
    $null = $xmlBuilder.AppendLine("            <pubDate>$($article.Date.ToString('ddd, dd MMM yyyy HH:mm:ss +0000'))</pubDate>")
    $null = $xmlBuilder.AppendLine("            <dc:creator><![CDATA[Admin]]></dc:creator>")
    $null = $xmlBuilder.AppendLine("            <guid isPermaLink=`"false`">https://example.com/?p=$postId</guid>")
    $null = $xmlBuilder.AppendLine("            <description></description>")
    $null = $xmlBuilder.AppendLine("            <content:encoded><![CDATA[$($article.Content)]]></content:encoded>")
    $null = $xmlBuilder.AppendLine("            <excerpt:encoded><![CDATA[$($article.Excerpt)]]></excerpt:encoded>")
    $null = $xmlBuilder.AppendLine("            <wp:post_id>$postId</wp:post_id>")
    $null = $xmlBuilder.AppendLine("            <wp:post_name>$($article.Slug)</wp:post_name>")
    $null = $xmlBuilder.AppendLine("            <wp:post_parent>0</wp:post_parent>")
    $null = $xmlBuilder.AppendLine("            <wp:menu_order>0</wp:menu_order>")
    $null = $xmlBuilder.AppendLine("            <wp:post_type>post</wp:post_type>")
    $null = $xmlBuilder.AppendLine("            <wp:post_password></wp:post_password>")
    $null = $xmlBuilder.AppendLine("            <wp:is_sticky>0</wp:is_sticky>")
    $null = $xmlBuilder.AppendLine("            <wp:status>draft</wp:status>")
    $null = $xmlBuilder.AppendLine("            <category domain=`"category`" nicename=`"$($article.Category.ToLower())`">$($article.Category)</category>")
    
    foreach ($tag in $article.Tags) {
        $null = $xmlBuilder.AppendLine("            <category domain=`"post_tag`" nicename=`"$($tag.ToLower())`">$tag</category>")
    }
    
    $null = $xmlBuilder.AppendLine("            <wp:postmeta>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_key>_yoast_wpseo_title</wp:meta_key>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_value><![CDATA[$($article.SEOTitle)]]></wp:meta_value>")
    $null = $xmlBuilder.AppendLine("            </wp:postmeta>")
    $null = $xmlBuilder.AppendLine("            <wp:postmeta>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_key>_yoast_wpseo_metadesc</wp:meta_key>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_value><![CDATA[$($article.SEODescription)]]></wp:meta_value>")
    $null = $xmlBuilder.AppendLine("            </wp:postmeta>")
    $null = $xmlBuilder.AppendLine("            <wp:postmeta>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_key>_yoast_wpseo_focuskw</wp:meta_key>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_value><![CDATA[$($article.FocusKeyword)]]></wp:meta_value>")
    $null = $xmlBuilder.AppendLine("            </wp:postmeta>")
    $null = $xmlBuilder.AppendLine("            <wp:postmeta>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_key>rank_math_title</wp:meta_key>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_value><![CDATA[$($article.SEOTitle)]]></wp:meta_value>")
    $null = $xmlBuilder.AppendLine("            </wp:postmeta>")
    $null = $xmlBuilder.AppendLine("            <wp:postmeta>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_key>rank_math_description</wp:meta_key>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_value><![CDATA[$($article.SEODescription)]]></wp:meta_value>")
    $null = $xmlBuilder.AppendLine("            </wp:postmeta>")
    $null = $xmlBuilder.AppendLine("            <wp:postmeta>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_key>rank_math_focus_keyword</wp:meta_key>")
    $null = $xmlBuilder.AppendLine("                <wp:meta_value><![CDATA[$($article.FocusKeyword)]]></wp:meta_value>")
    $null = $xmlBuilder.AppendLine("            </wp:postmeta>")
    $null = $xmlBuilder.AppendLine("        </item>")
}

$null = $xmlBuilder.AppendLine("    </channel>")
$null = $xmlBuilder.AppendLine("</rss>")

$xmlPath = Join-Path $OutputDir "mdw_2026_wp_import.xml"
[System.IO.File]::WriteAllText($xmlPath, $xmlBuilder.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Generated: mdw_2026_wp_import.xml"

# Build CSV
$csvBuilder = [System.Collections.Generic.List[string]]::new()
$csvBuilder.Add("title,slug,content,excerpt,date,status,category,seo_title,seo_description,focus_keyword,tags")

foreach ($article in $articles) {
    $date = $article.Date.ToString('yyyy-MM-dd HH:mm:ss')
    $tags = $article.Tags -join "; "
    
    $fields = @(
        "`"$($article.Title -replace '"', '""')`"",
        "`"$($article.Slug)`"",
        "`"$($article.Content -replace '"', '""')`"",
        "`"$($article.Excerpt -replace '"', '""')`"",
        "`"$date`"",
        "`"draft`"",
        "`"$($article.Category)`"",
        "`"$($article.SEOTitle -replace '"', '""')`"",
        "`"$($article.SEODescription -replace '"', '""')`"",
        "`"$($article.FocusKeyword)`"",
        "`"$tags`""
    )
    
    $csvBuilder.Add(($fields -join ","))
}

$csvPath = Join-Path $OutputDir "mdw_2026_wp_import.csv"
[System.IO.File]::WriteAllLines($csvPath, $csvBuilder, [System.Text.Encoding]::UTF8)
Write-Host "Generated: mdw_2026_wp_import.csv"

# Summary
Write-Host ""
Write-Host "Summary:"
Write-Host "  Total articles: $($articles.Count)"
Write-Host "  Status: All posts are DRAFT"
Write-Host "  Schedule: 3 posts/week (Tue, Thu, Sat)"
Write-Host "  Start date: $($articles[0].Date.ToString('yyyy-MM-dd'))"
Write-Host "  End date: $($articles[-1].Date.ToString('yyyy-MM-dd'))"

$categories = @{}
foreach ($article in $articles) {
    $cat = $article.Category
    if ($categories.ContainsKey($cat)) {
        $categories[$cat]++
    } else {
        $categories[$cat] = 1
    }
}

Write-Host ""
Write-Host "Categories:"
foreach ($cat in ($categories.Keys | Sort-Object)) {
    Write-Host "  - $cat`: $($categories[$cat])"
}

Write-Host ""
Write-Host "All done!"
