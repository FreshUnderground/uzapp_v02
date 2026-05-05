
$inputPath = "C:\Users\DIEU-MERCI\Downloads\inves2504808_11wdvwt.sql"
$outputPath = "C:\Users\DIEU-MERCI\Music\uzaapp\migration_export.sql"

Write-Host "Starting migration with Owner ID support..."

$content = [System.IO.File]::ReadAllText($inputPath)

$sqlOutput = @("-- Migration Data Export with Owner ID`n")
$sqlOutput += "SET FOREIGN_KEY_CHECKS = 0;`n"
$sqlOutput += "TRUNCATE TABLE products;`n"
$sqlOutput += "TRUNCATE TABLE shops;`n"
$sqlOutput += "TRUNCATE TABLE categories;`n"
$sqlOutput += "SET FOREIGN_KEY_CHECKS = 1;`n`n"

$valueRegex = "'((?:[^'\\]|\\.)*)'|NULL|(\d+)"

function Fix-SQLString($s) {
    if ($null -eq $s -or $s -eq "NULL") { return "NULL" }
    if ($s.StartsWith("'") -and $s.EndsWith("'")) {
        $s = $s.Substring(1, $s.Length - 2)
    }
    $s = $s -replace "\\'", "'" -replace '\\"', '"' -replace "\\\\", "\" -replace "\\n", "`n" -replace "\\r", "`r" -replace "\\t", "`t"
    $s = $s.Replace("'", "''")
    return "'$s'"
}

$existingShops = New-Object System.Collections.Generic.HashSet[string]
$existingCategories = New-Object System.Collections.Generic.HashSet[string]

# --- Categories ---
Write-Host "Extracting Categories..."
$sqlOutput += "-- Categories`n"
$catMatches = [regex]::Matches($content, "INSERT INTO ``t_categorie`` .*? VALUES\s*(.*?);", [System.Text.RegularExpressions.RegexOptions]::Singleline)
foreach ($m in $catMatches) {
    $vals = $m.Groups[1].Value
    $records = $vals -split "\)\s*,\s*\("
    foreach ($r in $records) {
        $r = $r.Trim("(", ")")
        $parts = [regex]::Matches($r, $valueRegex).Groups | Where-Object { $_.Name -eq "0" } | ForEach-Object { $_.Value }
        if ($parts.Count -ge 3) {
            $nameVal = Fix-SQLString($parts[1])
            $name = $nameVal.ToUpper().Trim("'")
            if (!$existingCategories.Contains($name)) {
                $img = Fix-SQLString($parts[2])
                $sqlOutput += "INSERT INTO categories (name, icon) VALUES ('$name', $img);`n"
                $existingCategories.Add($name) | Out-Null
            }
        }
    }
}

# --- Shops ---
Write-Host "Extracting Shops..."
$sqlOutput += "`n-- Shops`n"
$shopMatches = [regex]::Matches($content, "INSERT INTO ``t_utilisateur`` .*? VALUES\s*(.*?);", [System.Text.RegularExpressions.RegexOptions]::Singleline)
foreach ($m in $shopMatches) {
    $vals = $m.Groups[1].Value
    $records = $vals -split "\)\s*,\s*\("
    foreach ($r in $records) {
        $r = $r.Trim("(", ")")
        $parts = [regex]::Matches($r, $valueRegex).Groups | Where-Object { $_.Name -eq "0" } | ForEach-Object { $_.Value }
        if ($parts.Count -ge 7) {
            $phoneVal = Fix-SQLString($parts[2])
            $phone = $phoneVal.Trim("'")
            if (!$existingShops.Contains($phone)) {
                $name = Fix-SQLString($parts[5]).ToUpper()
                $address = Fix-SQLString($parts[3])
                $desc = Fix-SQLString($parts[4])
                $logo = Fix-SQLString($parts[6])
                if ($name -eq "''") { $name = "'BOUTIQUE SANS NOM'" }
                
                # Include owner_id as requested (phone number)
                $sqlOutput += "INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ($name, $address, $desc, $logo, '$phone', '$phone');`n"
                $existingShops.Add($phone) | Out-Null
            }
        }
    }
}

# --- Products ---
Write-Host "Extracting Products..."
$sqlOutput += "`n-- Products`n"
$prodMatches = [regex]::Matches($content, "INSERT INTO ``tproduit`` .*? VALUES\s*(.*?);", [System.Text.RegularExpressions.RegexOptions]::Singleline)
foreach ($m in $prodMatches) {
    $vals = $m.Groups[1].Value
    $records = $vals -split "\)\s*,\s*\("
    foreach ($r in $records) {
        $r = $r.Trim("(", ")")
        $parts = [regex]::Matches($r, $valueRegex).Groups | Where-Object { $_.Name -eq "0" } | ForEach-Object { $_.Value }
        
        if ($parts.Count -ge 17) {
            $p_shop_phone_raw = Fix-SQLString($parts[15])
            $p_shop_phone = $p_shop_phone_raw.Trim("'")
            
            if (!$existingShops.Contains($p_shop_phone)) {
                $sqlOutput += "INSERT INTO shops (name, phone, owner_id) VALUES ('BOUTIQUE INCONNUE ($p_shop_phone)', '$p_shop_phone', '$p_shop_phone');`n"
                $existingShops.Add($p_shop_phone) | Out-Null
            }
            
            $p_cat_name_raw = Fix-SQLString($parts[13]).ToUpper()
            $p_cat_name = $p_cat_name_raw.Trim("'")
            if (!$existingCategories.Contains($p_cat_name)) {
                $sqlOutput += "INSERT INTO categories (name) VALUES ('$p_cat_name');`n"
                $existingCategories.Add($p_cat_name) | Out-Null
            }
            
            $p_title = Fix-SQLString($parts[7]).ToUpper()
            $p_scat = Fix-SQLString($parts[3]).ToUpper()
            $p_name = if ($p_title -ne "''") { $p_title } else { $p_scat }
            if ($p_name -eq "''") { $p_name = "'PRODUIT SANS NOM'" }
            $p_desc = Fix-SQLString($parts[5])
            $p_price_raw = $parts[11].Trim("'").Replace(",", ".")
            $priceMatch = [regex]::Match($p_price_raw, "(\d+(?:\.\d+)?)")
            $p_price = if ($priceMatch.Success) { $priceMatch.Value } else { "0" }
            $images = Fix-SQLString($parts[1])
            $shopSubquery = "(SELECT id FROM shops WHERE phone = '$p_shop_phone' LIMIT 1)"
            $catSubquery = "(SELECT id FROM categories WHERE name = '$p_cat_name' LIMIT 1)"
            
            $sqlOutput += "INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ($p_name, $p_desc, $p_price, $images, $shopSubquery, $catSubquery);`n"
        }
    }
}

$sqlOutput | Out-File -FilePath $outputPath -Encoding utf8
Write-Host "Finished! Exported to $outputPath"
