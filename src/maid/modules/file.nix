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
          description = "Path of the resulting file.";
          defaultText = lib.literalExpression ''"<name>"'';
        };

        source = mkOption {
          type = types.coercedTo types.path (p: "${p}") types.str;
          description = "Source file that we are linking into.";
        };

        text = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.lines;
          description = "Text to write to the resulting file, as an alternative to `.source`.";
        };

        executable = mkOption {
          type = types.bool;
          default = false;
          description = "When `.text` is set, whether the resulting file will be executable.";
        };

        mode = mkOption {
          type = types.str;
          default = "symlink";
          description = "If set to something else than `\"symlink\"`, the file is copied instead of symlinked, with the given file mode.";
          example = "0600";
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
    You can defer some variables to be looked-up at runtime, by using mustache syntax.
    For example `.source = "{{home}}/foo"`.


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

  mkFileOption =
    { env }:
    mkOption {
      type = types.attrsOf (types.submodule theSubmodule);
      description = ''
        Files to symlink relative to $${env}.

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

  mkFileConfig =
    {
      root,
      fromConfig,
      staticSuffix,
    }:
    (builtins.concatMap (value: [
      # Link from final path to static
      (link {
        from = "${root}/${value.target}";
        to = "${staticPath}${staticSuffix}/${value.target}";
      })
      # Link from unique static to destination
      (link {
        from = "${uniqueStaticPath}${staticSuffix}/${value.target}";
        to = "${value.source}";
      })
    ]) (attrValues fromConfig))
    ++ [
      # Link static to unique static
      (link {
        from = "${staticPath}${staticSuffix}";
        to = "${uniqueStaticPath}${staticSuffix}";
      })
    ];
in
{
  options = {
    file = {
      home = mkFileOption {
        env = "HOME";
      };

      xdg_config = mkFileOption {
        env = "XDG_CONFIG_HOME";
      };

      xdg_data = mkFileOption {
        env = "XDG_DATA_HOME";
      };

      xdg_runtime = mkFileOption {
        env = "XDG_RUNTIME_DIR";
      };

      xdg_cache = mkFileOption {
        env = "XDG_CACHE_HOME";
      };

      xdg_state = mkFileOption {
        env = "XDG_STATE_HOME";
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
      (mkFileConfig {
        root = "{{home}}";
        fromConfig = config.file.home;
        staticSuffix = "";
      })
      (mkFileConfig {
        root = "{{xdg_config_home}}";
        fromConfig = config.file.xdg_config;
        staticSuffix = "-xdg-config";
      })
      (mkFileConfig {
        root = "{{xdg_data_home}}";
        fromConfig = config.file.xdg_data;
        staticSuffix = "-xdg-data";
      })
      (mkFileConfig {
        root = "{{xdg_runtime_dir}}";
        fromConfig = config.file.xdg_runtime;
        staticSuffix = "-xdg-runtime";
      })
      (mkFileConfig {
        root = "{{xdg_cache_home}}";
        fromConfig = config.file.xdg_cache;
        staticSuffix = "-xdg-cache";
      })
      (mkFileConfig {
        root = "{{xdg_state_home}}";
        fromConfig = config.file.xdg_state;
        staticSuffix = "-xdg-state";
      })
    ];
  };
}
