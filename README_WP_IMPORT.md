# WordPress Import Generator - MDW 2026

## Overview

This PowerShell script processes markdown articles from the `docs/artykuly/` directory and generates two WordPress-compatible export files:
- **mdw_2026_wp_import.xml** - WordPress WXR (XML) format for direct import
- **mdw_2026_wp_import.csv** - CSV format for reference and additional import options

## Generated Files

### mdw_2026_wp_import.xml
WordPress WXR (WordPress eXtendable RSS) format. Features:
- All posts imported as **DRAFT** status
- Standard WordPress post fields (title, content, excerpt, slug)
- **Yoast SEO** metadata:
  - `_yoast_wpseo_title` (Meta Title)
  - `_yoast_wpseo_metadesc` (Meta Description)
  - `_yoast_wpseo_focuskw` (Focus Keyword)
- **RankMath** SEO compatibility:
  - `rank_math_title`
  - `rank_math_description`
  - `rank_math_focus_keyword`
- Categories and tags
- Publication dates (3 posts per week: Tuesday, Thursday, Saturday)

### mdw_2026_wp_import.csv
CSV export for spreadsheet review or alternative import methods. Columns:
- `title` - Article title
- `slug` - URL-friendly slug
- `content` - Full article content
- `excerpt` - Short description
- `date` - Publication date (YYYY-MM-DD HH:MM:SS)
- `status` - Always "draft"
- `category` - Article category
- `seo_title` - SEO title tag (max 60 chars)
- `seo_description` - Meta description (140-155 chars)
- `focus_keyword` - Primary keyword for SEO
- `tags` - Semicolon-separated tags

## Import Summary

**47 Articles Processed**

### By Category:
- Polskie winiarstwo: 15 articles
- Jaslo i region: 11 articles
- Uczestnik i degustacja: 10 articles
- Enoturystyka: 5 articles
- Wydarzenie: 6 articles

### Publication Schedule:
- **Start Date:** Tuesday, May 18, 2026
- **End Date:** Wednesday, August 26, 2026
- **Frequency:** 3 posts per week (Tuesday, Thursday, Saturday)
- **Status:** All posts are DRAFT (no automatic publishing)

## How to Import into WordPress

### Method 1: Using XML (Recommended)
1. Go to WordPress Admin → Tools → Import
2. Select "WordPress"
3. Click "Install Now" (if not already installed)
4. Activate and click "Run Importer"
5. Choose the `mdw_2026_wp_import.xml` file
6. Map authors (can map to existing admin user)
7. Download attachments: No (unless media is included)
8. Click "Submit"

### Method 2: Using CSV
Some WordPress plugins (e.g., WP All Import Pro) support CSV import for more control over field mapping.

## SEO Metadata Details

### Focus Keywords
Generated based on article content:
- "Międzynarodowe Dni Wina w Jaśle" - For articles about the event
- "polskie wino" - For Polish wine-related articles
- "wino" - Default fallback

### Meta Titles
- Format: `[First 35 chars of title]... - Międzynarodowe Dni Wina w Jaśle`
- Maximum length: 60 characters
- Compatible with Yoast SEO and RankMath

### Meta Descriptions
- Length: 140-155 characters
- Includes relevant keywords
- Encourages click-through from search results
- Always mentions "Międzynarodowe Dni Wina" or the event context

## Content Processing

The script performs these operations on each article:

1. **Frontmatter Extraction**
   - Parses YAML frontmatter for title and description
   - Separates frontmatter from body content

2. **Content Cleaning**
   - Removes reviewer comments: "## Komentarz dla recenzentki"
   - Removes author notes: "## Komentarz autora"
   - Removes editorial notes: "## Uwagi do tego materiału"
   - Removes Google Forms survey links

3. **Slug Generation**
   - Lowercase conversion
   - Removes file extensions
   - Removes leading/trailing hyphens

4. **Category Assignment**
   - Based on directory path:
     - `wydarzenie/` → "Wydarzenie"
     - `uczestnik-i-degustacja/` → "Uczestnik i degustacja"
     - `polskie-winiarstwo/` → "Polskie winiarstwo"
     - `enoturystyka/` → "Enoturystyka"
     - `jaslo-historia-srodowisko/` → "Jasło i region"

5. **Tag Generation**
   - Automatic tags: category name, "wino", "MDW"
   - Content-based tags: "degustacja", "Polskie winiarstwo", "enoturystyka", "Jasło"
   - Maximum 5 tags per article

## Post-Import Steps

1. **Review Draft Posts**
   - Check that formatting is correct
   - Verify SEO metadata in Yoast/RankMath
   - Test slug URLs

2. **Schedule Publishing**
   - Posts are imported as DRAFT
   - Manually assign scheduled dates or use the pre-generated dates
   - Consider using WordPress scheduling plugins for bulk scheduling

3. **Optimize Featured Images**
   - The current export doesn't include images
   - Add featured images manually or via bulk upload

4. **Verify SEO Settings**
   - Check Yoast SEO settings per post
   - Ensure RankMath is configured correctly
   - Review focus keywords and readability

## Running the Generator

```powershell
cd C:\Users\b.wilk\Documents\GitHub\MDW_2026
powershell -ExecutionPolicy Bypass -File .\generate_mdw_wp_import.ps1
```

The script will:
1. Scan the `docs/artykuly/` directory
2. Process all `.md` files (excluding `index.md`)
3. Generate XML and CSV files in the repository root
4. Display a summary with article count and publication schedule

## Notes

- **Encoding:** All files are UTF-8 encoded (with Polish characters preserved)
- **CDATA Sections:** Content is wrapped in CDATA to safely include special characters
- **Post Status:** All posts are imported as DRAFT to allow review before publishing
- **Publication Dates:** Generated sequentially starting May 12, 2026 (Tuesday)
- **Revisions:** If you need to re-import, delete drafts from WordPress or update the script

## Troubleshooting

### XML Import Fails
- Ensure the file is valid UTF-8 encoding
- Try importing with "WordPress" importer plugin installed
- Check server PHP memory limit (increase if needed)

### SEO Metadata Not Showing
- Ensure Yoast SEO or RankMath is installed and activated
- Check that meta fields are properly mapped
- Verify post is saved after import

### Polish Characters Appear Garbled
- Verify WordPress database charset is UTF-8
- Check browser encoding is set to UTF-8
- Re-export and check file encoding

---

**Generated:** 2026-05-05  
**Articles:** 47  
**Format:** WordPress WXR 1.2  
**Compatibility:** Yoast SEO + RankMath
