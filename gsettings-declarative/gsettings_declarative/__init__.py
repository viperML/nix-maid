from typing import Any, List, Tuple, Dict, cast
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
    schema_obj = SETTINGS_SCHEMA_SOURCE.lookup(schema, True)
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
    schema_obj = SETTINGS_SCHEMA_SOURCE.lookup(schema, True)
    if not schema_obj:
        raise RuntimeError(f"Schema '{schema}' not found.")
    key_obj = schema_obj.get_key(key)
    type_str = key_obj.get_value_type().dup_string()
    try:
        variant = GLib.Variant(type_str, value)
        settings.set_value(key, variant)
    except Exception as e:
        raise RuntimeError(f"Failed to set {schema}::{key} to {value}: {e}")

def resolve_gsettings(config: Dict[str, Any]) -> List[Tuple[str, str, Any]]:
    """
    Resolves a list of gsettings schema+key+value, from a nested json object.

    E.g. {"org": {"gnome": {"desktop": {"interface": {"color-scheme": "dark", "icon-theme": "Adwaita"}}}}} ->
         [ ("org.gnome.desktop.interface", "color-scheme", "dark")
         , ("org.gnome.desktop.interface", "icon-theme", "Adwaita")
         ]
    """
    def _resolve_recursive(obj: Any, path_parts: List[str]) -> List[Tuple[str, str, Any]]:
        results: List[Tuple[str, str, Any]] = []

        if isinstance(obj, dict):
            # Type cast to help the type checker understand this is a dictionary
            dict_obj = cast(Dict[str, Any], obj)

            for key, value in dict_obj.items():
                # Ensure key is a string
                str_key = str(key)
                current_path = path_parts + [str_key]

                # If the value is a dict, we need to go deeper
                if isinstance(value, dict):
                    # Type cast for the nested dictionary
                    value_dict = cast(Dict[str, Any], value)

                    # Check if this dict contains only non-dict values (i.e., it's the final level with key-value pairs)
                    if all(not isinstance(v, dict) for v in value_dict.values()):
                        # This is the final level - treat current_path as schema and dict items as key-value pairs
                        schema = ".".join(current_path)
                        for setting_key, setting_value in value_dict.items():
                            # Ensure setting_key is a string
                            str_setting_key = str(setting_key)
                            results.append((schema, str_setting_key, setting_value))
                    else:
                        # Continue recursing
                        results.extend(_resolve_recursive(value_dict, current_path))
                else:
                    # This is a direct key-value pair at this level
                    if len(current_path) > 1:
                        schema = ".".join(current_path[:-1])
                        setting_key = current_path[-1]
                        results.append((schema, setting_key, value))

        return results

    return _resolve_recursive(config, [])

def resolve_dconf(key: str):
    """
    Resolves the gsetting schema+key that corresponds to a given dconf
    key.

    E.g. "/org/gnome/desktop/interface/color-scheme" -> ("org.gnome.desktop.interface", "color-scheme")
    """
    path, gsettings_key = key.rsplit("/", 1)
    path = path + "/"  # gsettings schema paths always end with /

    # Find the schema whose path matches
    for schema_id in ALL_SCHEMAS:
        schema = SETTINGS_SCHEMA_SOURCE.lookup(schema_id, True)
        if schema is not None and schema.get_path() == path:
            return (schema_id, gsettings_key)

    raise RuntimeError(f"No GSettings schema found for dconf path '{path}'")

def main():
    parser = argparse.ArgumentParser(description="Configure GSettings declaratively.")
    parser.add_argument("manifest", help="Path to the manifest file.")

    args = parser.parse_args()

    with open(args.manifest, 'r') as file:
        manifest = json.load(file)


    any_error = False

    gsettings_settings = resolve_gsettings(manifest["settings"])
    for (schema, key, value) in gsettings_settings:
        print(Fore.LIGHTBLACK_EX, "▶ Configuring ", Style.RESET_ALL, f"{schema} {key} {value}", file=sys.stderr, sep="")
        try:
            check_type(schema, key, value)
            configure(schema, key, value)
        except RuntimeError as e:
            print(" ↳  ", Fore.RED, "Error: ", Style.RESET_ALL, e, file=sys.stderr, sep="")
            any_error = True
            continue

    for (key, value) in manifest["dconf_settings"].items():
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
