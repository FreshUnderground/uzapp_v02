
import re
import json
import os

# Define the paths
dump_path = r'C:\Users\DIEU-MERCI\Downloads\inves2504808_11wdvwt.sql'
artifact_dir = r'C:\Users\DIEU-MERCI\.gemini\antigravity\brain\5849383f-f109-4b85-9904-6bf458b042c5'
output_path = os.path.join(artifact_dir, 'migration_export.sql')

def extract_inserts(table_name, content):
    pattern = rf'INSERT INTO `{table_name}` .*? VALUES\s*(.*?);'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        # Try without backticks
        pattern = rf'INSERT INTO {table_name} .*? VALUES\s*(.*?);'
        match = re.search(pattern, content, re.DOTALL)
    
    if match:
        values_str = match.group(1)
        return values_str
    return ""

def parse_values(values_str):
    items = []
    in_quotes = False
    quote_char = ''
    buffer = ""
    bracket_depth = 0
    
    for char in values_str:
        if (char == "'" or char == '"') and not (buffer and buffer[-1] == '\\'):
            if not in_quotes:
                in_quotes = True
                quote_char = char
            elif char == quote_char:
                in_quotes = False
            buffer += char
        elif char == '(' and not in_quotes:
            bracket_depth += 1
            if bracket_depth == 1:
                buffer = ""
            else:
                buffer += char
        elif char == ')' and not in_quotes:
            bracket_depth -= 1
            if bracket_depth == 0:
                items.append(buffer)
                buffer = ""
            else:
                buffer += char
        else:
            buffer += char
    return items

def split_csv_line(line):
    parts = []
    current = ""
    in_quotes = False
    quote_char = ''
    for i, char in enumerate(line):
        if (char == "'" or char == '"') and not (current and current[-1] == '\\'):
            if not in_quotes:
                in_quotes = True
                quote_char = char
            elif char == quote_char:
                in_quotes = False
            current += char
        elif char == ',' and not in_quotes:
            parts.append(current.strip())
            current = ""
        else:
            current += char
    parts.append(current.strip())
    # Clean up quotes and handle NULL
    result = []
    for p in parts:
        if p.upper() == 'NULL':
            result.append(None)
        else:
            # Strip outer quotes
            if (p.startswith("'") and p.endswith("'")) or (p.startswith('"') and p.endswith('"')):
                result.append(p[1:-1])
            else:
                result.append(p)
    return result

if not os.path.exists(dump_path):
    print(f"Error: Dump file not found at {dump_path}")
    exit(1)

with open(dump_path, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# 1. Categories
cat_values = extract_inserts('t_categorie', content)
cats = parse_values(cat_values)
category_map = {} 
category_sql = []

for c in cats:
    parts = split_csv_line(c)
    if len(parts) >= 2:
        old_id = parts[0]
        name = parts[1]
        img = parts[2] if len(parts) > 2 else ""
        category_map[name] = old_id
        category_sql.append(f"INSERT INTO categories (id, name, image_url) VALUES ('{old_id}', '{name}', '{img}');")

# 2. Shops (t_utilisateur)
shop_values = extract_inserts('t_utilisateur', content)
shops = parse_values(shop_values)
shop_sql = []
shop_id_map = {} 

for s in shops:
    parts = split_csv_line(s)
    if len(parts) >= 6:
        phone = parts[2]
        address = (parts[3] or "").replace("'", "''")
        desc = (parts[4] or "").replace("'", "''")
        name = (parts[5] or "SANS NOM").upper().replace("'", "''")
        logo = parts[6] or ""
        shop_id = parts[0]
        shop_id_map[phone] = shop_id
        
        shop_sql.append(f"INSERT INTO shops (id, name, address, description, logo_url, phone) VALUES ('{shop_id}', '{name}', '{address}', '{desc}', '{logo}', '{phone}');")

# 3. Products
prod_matches = re.finditer(r'INSERT INTO `tproduit` .*? VALUES\s*(.*?);', content, re.DOTALL)
product_sql = []
for match in prod_matches:
    prod_values = match.group(1)
    prods = parse_values(prod_values)
    for p in prods:
        parts = split_csv_line(p)
        if len(parts) >= 17:
            p_id = parts[0]
            images = parts[1] # JSON string original
            p_name = (parts[7] if parts[7] else parts[3]).upper().replace("'", "''")
            p_desc = (parts[5] or "").replace("'", "''")
            p_price = parts[11] or "0"
            if ',' in p_price and '.' not in p_price: p_price = p_price.replace(',', '.') # Handle comma decimal
            p_old_price = parts[14] or "0"
            if ',' in p_old_price and '.' not in p_old_price: p_old_price = p_old_price.replace(',', '.')
            
            p_cat_name = parts[13]
            p_shop_phone = parts[15]
            
            p_cat_id = category_map.get(p_cat_name, "")
            p_shop_id = shop_id_map.get(p_shop_phone, "")
            
            product_sql.append(f"INSERT INTO products (id, name, description, price, old_price, image_urls, shop_id, category_id) VALUES ('{p_id}', '{p_name}', '{p_desc}', '{p_price}', '{p_old_price}', '{images}', '{p_shop_id}', '{p_cat_id}');")

os.makedirs(artifact_dir, exist_ok=True)
with open(output_path, 'w', encoding='utf-8') as f:
    f.write("-- Migration script for Categories, Shops and Products\n\n")
    f.write("-- Categories\n")
    f.write("\n".join(category_sql))
    f.write("\n\n-- Shops\n")
    f.write("\n".join(shop_sql))
    f.write("\n\n-- Products\n")
    f.write("\n".join(product_sql))

print(f"Generated {len(category_sql)} categories, {len(shop_sql)} shops, and {len(product_sql)} products in {output_path}")
