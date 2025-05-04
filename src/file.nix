{ config, lib, ... }:
let
  inherit (lib) mkOption types mkDefault;
  inherit (builtins) attrValues;

  theSubmodule =
    { config, name, ... }:
    {
      options = {
        target = mkOption {
          type = types.str;
          description = "Name of symlink, relative";
        };

        source = lib.mkOption {
          type = lib.types.path;
          description = "Path of the source file.";
        };
      };

      config = {
        target = mkDefault name;
      };

    };

  staticPath = "{{xdg_state_home}}/nix-maid/{{hash}}/static";
in
{
  options = {
    file = {
      home = mkOption {
        type = types.attrsOf (types.submodule theSubmodule);
        description = "TODO.";
        default = { };
      };

      xdg_config = mkOption {
        type = types.attrsOf (types.submodule theSubmodule);
        description = "TODO.";
        default = { };
      };
    };
  };

  config = {
    systemd.tmpfiles.dynamicRules = lib.mkMerge [
      [
        "d {{xdg_state_home}}/nix-maid 0755 {{user}} {{group}} - -"
        "d {{xdg_state_home}}/nix-maid/{{hash}} 0755 {{user}} {{group}} - -"
      ]
      # File
      (map (value: "L+ {{home}}/${value.target} - - - - ${staticPath}/${value.target}") (
        attrValues config.file.home
      ))
      (map (value: "L+ ${staticPath}/${value.target} - - - - ${value.source}") (
        attrValues config.file.home
      ))
      # XDG Config
      (map (
        value: "L+ {{xdg_config_home}}/${value.target} - - - - ${staticPath}-xdg-config/${value.target}"
      ) (attrValues config.file.xdg_config))
      (map (value: "L+ ${staticPath}-xdg-config/${value.target} - - - - ${value.source}") (
        attrValues config.file.xdg_config
      ))
    ];
  };
}
