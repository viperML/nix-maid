{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) types;
  format = pkgs.formats.json { };
  inherit (lib) mkOption literalExpression;
in
{

  options = {
    kconfig = mkOption {
      description = ''
        Declarative configuration for KDE Plasma.

        Some changes may need a restart of the affected application or the whole system.
      '';
      example = literalExpression ''
        {
          settings = {
            kwinrc = {
              Desktops.Number = 4;
            };
          };
        }
      '';
      type = types.submodule {
        options = {
          settings = lib.mkOption {
            type = types.attrsOf format.type;
            description = "Configuration for each KDE Plasma file. The value can be anything serializable to json";
            example = literalExpression ''
              {
                kwinrc = {
                  Desktops.Number = 4;
                };
              }
            '';
          };

          manifest = lib.mkOption {
            visible = false;
            readOnly = true;
            default = format.generate "kconfig-manifest.json" {
              files = config.kconfig.settings;
            };
          };

          package = lib.mkOption {
            type = types.package;
            default = pkgs.callPackage ../../../kconfig-declarative/package.nix { };
            visible = false;
          };
        };
      };
    };
  };

  config = lib.mkIf ((builtins.attrNames config.kconfig.settings) != [ ]) {
    systemd.services.maid-kconfig = {
      wantedBy = [
        config.maid.systemdTarget
        "plasma-plasmashell.service"
      ];
      before = [ "plasma-plasmashell.service" ];
      restartIfChanged = true;
      restartTriggers = [ config.kconfig.manifest ];
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        ExecStart = "${lib.getExe config.kconfig.package} apply ${config.kconfig.manifest}";
      };
    };
  };
}
