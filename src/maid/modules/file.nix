{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkDefault
    literalExpression
    attrsToList
    ;
  inherit (builtins) attrValues;

  theSubmodule =
    {
      config,
      name,
      options,
      ...
    }:
    {
      options = {
        target = mkOption {
          type = types.str;
          description = "Name of symlink, relative";
        };

        source = mkOption {
          type = types.coercedTo types.path (p: "${p}") types.str;
          description = "Path of the source file.";
        };

        text = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.lines;
          description = "Text of the file.";
        };

        executable = mkOption {
          type = types.bool;
          default = false;
          description = "When text is set, wether the resulting file will be executable.";
        };
      };

      config = {
        target = mkDefault name;
        source = lib.mkIf (config.text != null) (
          lib.mkDerivedConfig options.text (
            t:
            pkgs.writeTextFile {
              name = "nix-maid-" + lib.replaceStrings [ "/" ] [ "-" ] name;
              inherit (config) executable;
              text = t;
            }
          )
        );
      };
    };

  uniqueStaticPath = "{{xdg_state_home}}/nix-maid/{{hash}}/static";
  staticPath = "{{xdg_state_home}}/nix-maid/static";

  vars = import ../vars.nix;
  varsDesc = ''
    You can defer some variables to be looked-up at runtime, by using mustache syntax,
    for example `.source = "{{home}}/foo"`.


    The variables that can be deferred with mustache syntax are the following:
    ```
    ${lib.concatStringsSep "\n" (
      map ({ name, value }: "{{${name}}} -> \"${value}\"") (attrsToList vars)
    )}
    {{hash}} -> "some unique hash"
    ```
  '';

  link =
    {
      from,
      to,
    }:
    "L+ ${from} - - - - ${to}";
in
{
  options = {
    file = {
      home = mkOption {
        type = types.attrsOf (types.submodule theSubmodule);
        description = ''
          Files to symlink relative to $HOME.

          ${varsDesc}
        '';
        default = { };
        example = literalExpression ''
          {
            "foo".source = pkgs.coreutils;
            "bar".text = "Hello";
            "baz".source = "{{home}}/.gitconfig";
          }
        '';
      };

      xdg_config = mkOption {
        type = types.attrsOf (types.submodule theSubmodule);
        description = ''
          Files to symlink relative to $XDG_CONFIG_HOME.

          ${varsDesc}
        '';
        default = { };
        example = literalExpression ''
          {
            "foo".source = pkgs.coreutils;
            "bar".text = "Hello";
            "baz".source = "{{home}}/.gitconfig";
          }
        '';
      };
    };
  };

  config = {

    # We can't assume xdg_config_home == home/.config

    systemd.tmpfiles.dynamicRules = lib.mkMerge [
      [
        "d {{xdg_state_home}}/nix-maid 0755 {{user}} {{group}} - -"
        "d {{xdg_state_home}}/nix-maid/{{hash}} 0755 {{user}} {{group}} - -"
      ]
      # File
      (map (
        value:
        link {
          from = "{{home}}/${value.target}";
          to = "${staticPath}/${value.target}";
        }
      ) (attrValues config.file.home))
      (map (
        value:
        link {
          from = "${uniqueStaticPath}/${value.target}";
          to = "${value.source}";
        }
      ) (attrValues config.file.home))
      [
        (link {
          from = "${staticPath}";
          to = "${uniqueStaticPath}";
        })
      ]
      # XDG Config
      (map (
        value:
        link {
          from = "{{xdg_config_home}}/${value.target}";
          to = "${staticPath}-xdg-config/${value.target}";
        }
      ) (attrValues config.file.xdg_config))
      (map (
        value:
        link {
          from = "${uniqueStaticPath}-xdg-config/${value.target}";
          to = "${value.source}";
        }
      ) (attrValues config.file.xdg_config))
      [
        (link {
          from = "${staticPath}-xdg-config";
          to = "${uniqueStaticPath}-xdg-config";
        })
      ]
    ];
  };
}
