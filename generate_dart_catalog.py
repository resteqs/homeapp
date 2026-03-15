import importlib.util
from pathlib import Path

"""Generate an offline Dart grocery catalog from the Python source dataset.

Input:
- generate_groceries.py (computed PRODUCTS tuples: category_key, en_name, de_name)

Output:
- lib/data/grocery_catalog.dart
    - groceryCatalog: localized product names
    - groceryCategoryKeyByNameLowerEn/De: exact name -> category key maps
"""


def _load_products():
    """Load PRODUCTS from generate_groceries.py without brittle text parsing."""
    src = Path("generate_groceries.py")
    spec = importlib.util.spec_from_file_location("generate_groceries", src)
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load generate_groceries.py")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    products = getattr(module, "PRODUCTS", None)
    if not isinstance(products, list):
        raise RuntimeError("generate_groceries.py must expose PRODUCTS as a list")
    return products


def main():
    products = _load_products()

    en_names = set()
    de_names = set()
    # Lookup maps used at runtime for quick local category resolution.
    en_category_by_name = {}
    de_category_by_name = {}

    for entry in products:
        if len(entry) != 3:
            continue
        category_key, en_name, de_name = entry
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

        # Exact lowercased name maps are generated to avoid remote category
        # lookups for known products during add/edit flows.
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
