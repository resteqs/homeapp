import re


def main():
    with open("generate_groceries.py", "r") as f:
        content = f.read()

    match = re.search(r"PRODUCTS\s*=\s*\[(.*?)\]", content, re.DOTALL)
    if not match:
        print("Couldn't find PRODUCTS")
        return

    products_str = match.group(1)

    pattern = re.compile(r'\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)')

    en_names = set()
    de_names = set()
    en_category_by_name = {}
    de_category_by_name = {}

    for m in pattern.finditer(products_str):
        category_key = m.group(1)
        en_name = m.group(2)
        de_name = m.group(3)
        en_names.add(en_name)
        de_names.add(de_name)
        en_category_by_name[en_name.lower()] = category_key
        de_category_by_name[de_name.lower()] = category_key

    with open("lib/data/grocery_catalog.dart", "w") as f:
        f.write("// GENERATED CODE - DO NOT MODIFY BY HAND\n\n")
        f.write("const Map<String, List<String>> groceryCatalog = {\n")

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

        f.write("};\n")

        f.write("\nconst Map<String, String> groceryCategoryKeyByNameLowerEn = {\n")
        for name in sorted(en_category_by_name.keys()):
            escaped_name = name.replace("'", "\\'").replace("$", "\\$")
            escaped_category = en_category_by_name[name].replace("'", "\\'")
            f.write(f"  '{escaped_name}': '{escaped_category}',\n")
        f.write("};\n")

        f.write("\nconst Map<String, String> groceryCategoryKeyByNameLowerDe = {\n")
        for name in sorted(de_category_by_name.keys()):
            escaped_name = name.replace("'", "\\'").replace("$", "\\$")
            escaped_category = de_category_by_name[name].replace("'", "\\'")
            f.write(f"  '{escaped_name}': '{escaped_category}',\n")
        f.write("};\n")

    print(
        f"Generated lib/data/grocery_catalog.dart with {len(en_names)} EN and {len(de_names)} DE items."
    )


if __name__ == "__main__":
    main()
