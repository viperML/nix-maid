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

SETTINGS_SCHEMA_SOURCE = _settings_schema()

ALL_SCHEMAS = Gio.Settings.list_schemas() + Gio.Settings.list_relocatable_schemas()

def check_type(schema: str, key: str, value: Any):
    """
    For a given schema and key, checks if the provided value
    can be set. Returns True if the type matches, False otherwise.
    """
    schema_obj = SETTINGS_SCHEMA_SOURCE.lookup(schema, False)
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

def configure(schema: str, key: str, value: Any):
    """
    Configures the GSettings setting.
    """
    settings = Gio.Settings.new(schema)
    schema_obj = SETTINGS_SCHEMA_SOURCE.lookup(schema, False)
    if not schema_obj:
        raise RuntimeError(f"Schema '{schema}' not found.")
    key_obj = schema_obj.get_key(key)
    type_str = key_obj.get_value_type().dup_string()
    try:
        variant = GLib.Variant(type_str, value)
        settings.set_value(key, variant)
    except Exception as e:
        raise RuntimeError(f"Failed to set {schema}::{key} to {value}: {e}")

def resolve_dconf(key: str):
    """
    Resolves the gsetting schema+key that corresponds to a given dconf
    key.

    E.g. "/org/gnome/desktop/interface/color-scheme" -> ("org.gnome.desktop.interface", "color-scheme")
    """
    path, gsettings_key = key.rsplit("/", 1)
    path = "/" + path.rstrip("/").lstrip("/") + "/"  # gsettings schema paths always begin and end with /

    # Find the schema whose path matches
    for schema_id in ALL_SCHEMAS:
        schema = SETTINGS_SCHEMA_SOURCE.lookup(schema_id, False)
        if schema is not None and schema.get_path() == path:
            return (schema_id, gsettings_key)

    raise RuntimeError(f"No GSettings schema found for dconf path '{path}'")

def flatten_manifest(tree: dict, prefix, wip_manifest: dict, sep: str = ".") -> dict:
    '''Traverse the settings tree, and add all paths to branch ends as separate keys'''
    if not prefix:
        for key in tree.keys():
            if isinstance(tree[key], dict):
                flatten_manifest(tree[key], key, wip_manifest, sep=sep)
            else:
                wip_manifest[key] = tree[key] # Copy over the value
    else:
        for key in tree.keys():
            if isinstance(tree[key], dict):
                flatten_manifest(tree[key], f"{prefix}{sep}{key}", wip_manifest, sep=sep)
            else:
                wip_manifest[f"{prefix}{sep}{key}"] = tree[key]

    return wip_manifest

def main():
    parser = argparse.ArgumentParser(description="Configure GSettings declaratively.")
    parser.add_argument("manifest", help="Path to the manifest file.")

    args = parser.parse_args()

    with open(args.manifest, 'r') as file:
        manifest = json.load(file)

    settings = flatten_manifest(manifest["settings"], None, dict(), sep=".")
    dconf_settings = manifest["dconf_settings"]
    # print(settings, dconf_settings, sep="\n\n\n") # DEBUG

    any_error = False

    for (dkey, value) in settings.items():
        schema, key = dkey.rsplit("/", 1)
        print(Fore.LIGHTBLACK_EX, "▶ Configuring ", Style.RESET_ALL, f"{schema} {key} {value}", file=sys.stderr, sep="")
        try:
            check_type(schema, key, value)
            configure(schema, key, value)
        except RuntimeError as e:
            print(" ↳  ", Fore.RED, "Error: ", Style.RESET_ALL, e, file=sys.stderr, sep="")
            any_error = True
            continue

    for (key, value) in dconf_settings.items():
        print(Fore.LIGHTBLACK_EX, "▶ Configuring ", Style.RESET_ALL, f"{key} {value}", file=sys.stderr, sep="")
        try:
            schema, key = resolve_dconf(key)
            check_type(schema, key, value)
            configure(schema, key, value)
        except RuntimeError as e:
            print(" ↳  ", Fore.RED, "Error: ", Style.RESET_ALL, e, file=sys.stderr, sep="")
            any_error = True
            continue

    if any_error:
        print(file=sys.stderr)
        print(Fore.RED, "Some errors occurred while loading the gsettings configuration", Style.RESET_ALL, sep="", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
