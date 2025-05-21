from typing import Any
import argparse
import json
from gi.repository import Gio, GLib # type: ignore
import sys
from colorama import Fore, Style

def _settings_schema() -> Gio.SettingsSchemaSource:
    res = Gio.SettingsSchemaSource.get_default()
    if not res:
        raise RuntimeError("No default schema source found.")
    return res

SETTINGS_SCHEMA = _settings_schema()

def check_type(schema: str, key: str, value: Any):
    """
    For a given schema and key, checks if the provided value
    can be set. Returns True if the type matches, False otherwise.
    """
    schema_obj = SETTINGS_SCHEMA.lookup(schema, False)
    if not schema_obj:
        raise RuntimeError(f"Schema '{schema}' not found.")

    if not schema_obj.has_key(key):
        raise RuntimeError(f"Key '{key}' not found in schema '{schema}'.")

    key_obj = schema_obj.get_key(key)
    expected_type = key_obj.get_value_type()
    type_str = expected_type.dup_string()

    try:
        # Try to create a GLib.Variant of the expected type with the value
        GLib.Variant(type_str, value)
    except Exception as e:
        raise RuntimeError(f"Value '{value}' of type '{type(value).__name__}' does not match expected type '{type_str}'.") from e



def main():
    parser = argparse.ArgumentParser(description="Configure GSettings declaratively.")
    parser.add_argument("manifest", help="Path to the manifest file.")

    args = parser.parse_args()

    with open(args.manifest, 'r') as file:
        manifest = json.load(file)

    settings = manifest["settings"]

    for (schema, keys) in settings.items():
        for (key, value) in keys.items():
            print(Fore.LIGHTBLACK_EX, "▶ Configuring ", Style.RESET_ALL, f"{schema} {key} {value}", file=sys.stderr, sep="")
            try:
                check_type(schema, key, value)
            except RuntimeError as e:
                print(" ↳  ", Fore.RED, "Error: ", Style.RESET_ALL, e, file=sys.stderr, sep="")

                continue

if __name__ == "__main__":
    main()