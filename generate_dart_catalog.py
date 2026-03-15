import re

def main():
    with open('generate_groceries.py', 'r') as f:
        content = f.read()

    match = re.search(r'PRODUCTS\s*=\s*\[(.*?)\]', content, re.DOTALL)
    if not match:
        print("Couldn't find PRODUCTS")
        return

    products_str = match.group(1)
    
    pattern = re.compile(r'\(\s*"[^"]+"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)')
    
    en_names = set()
    de_names = set()
    
    for m in pattern.finditer(products_str):
        en_names.add(m.group(1))
        de_names.add(m.group(2))

    with open('lib/data/grocery_catalog.dart', 'w') as f:
        f.write('// GENERATED CODE - DO NOT MODIFY BY HAND\n\n')
        f.write('const Map<String, List<String>> groceryCatalog = {\n')
        
        f.write("  'en': [\n")
        for name in sorted(en_names):
            escaped = name.replace("'", "\\'").replace("$", "\\$")
            f.write(f"    '{escaped}',\n")
        f.write("  ],\n")

        f.write("  'de': [\n")
        for name in sorted(de_names):
            escaped = name.replace("'", "\\'").replace("$", "\\$")
            f.write(f"    '{escaped}',\n")
        f.write("  ],\n")
        
        f.write('};\n')

    print(f"Generated lib/data/grocery_catalog.dart with {len(en_names)} EN and {len(de_names)} DE items.")

if __name__ == '__main__':
    main()

