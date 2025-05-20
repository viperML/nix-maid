from typing import Any
from gi.repository import Gio, GLib # type: ignore

def list_schema_keys(schema_name: str):
    schema_source = Gio.SettingsSchemaSource.get_default()
    if not schema_source:
        print("No GSettings schema source found.")
        return

    schema = schema_source.lookup(schema_name, False)
    if not schema:
        print(f"Schema '{schema_name}' not found.")
        return

    print(f"Keys for schema '{schema_name}':")
    for key in schema.list_keys():
        print(key)

def check_type(schema: str, key: str, value: Any):
    """
    For a given schema and key, checks if the provided value
    can be set. Returns True if the type matches, False otherwise.
    """
    schema_source = Gio.SettingsSchemaSource.get_default()
    if not schema_source:
        print("No GSettings schema source found.")
        return False

    schema_obj = schema_source.lookup(schema, False)
    if not schema_obj:
        print(f"Schema '{schema}' not found.")
        return False

    if not schema_obj.has_key(key):
        print(f"Key '{key}' not found in schema '{schema}'.")
        return False

    key_obj = schema_obj.get_key(key)
    expected_type = key_obj.get_value_type()
    type_str = expected_type.dup_string()

    try:
        # Try to create a GLib.Variant of the expected type with the value
        GLib.Variant(type_str, value)
        return True
    except Exception as e:
        print(f"Type mismatch for {schema}::{key}: {e}")
        return False

def set_gsetting(schema: str, key: str, value: Any):
    pass

if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser(description="Configure GSettings declaratively.")
    parser.add_argument("manifest", help="Path to the manifest file.")

    args = parser.parse_args()

    with open(args.manifest, 'r') as file:
        manifest = json.load(file)

    print(manifest)

    settings = manifest["settings"]

    for (schema, keys) in settings.items():
        for (key, value) in keys.items():
            print(f"Configuring {schema} {key} {value}")
            print(check_type(schema, key, value))