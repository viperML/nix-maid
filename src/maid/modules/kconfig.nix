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
  sources = import ../../../npins;
in
{

  options = {
    kconfig = mkOption {
      description = ''
        Declarative configuration for KDE Plasma. Builds a manifest for [kconfig-declarative](https://github.com/viperML/kconfig-declarative).

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
      default = { };
      type = types.submodule {
        options = {
          settings = lib.mkOption {
            type = types.attrsOf format.type;
            default = { };
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
            description = "The kconfig-declarative package to use.";
            default = pkgs.callPackage sources.kconfig-declarative { };
            defaultText = literalExpression "<internal>";
          };
        };
      };
    };
  };

  config = {
    systemd.services.maid-kconfig =
      lib.mkIf ((builtins.attrNames config.kconfig.settings) != [ ])
        {
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

    tests.kconfig = {
      nodes.machine.users.users.alice.maid = {
        kconfig.settings.kwinrc = {
          Desktops.Number = 4;
        };
      };

      testScript =
        { nodes, ... }:
        ''
          machine.wait_for_unit("user@1000.service")
          machine.wait_for_unit("maid-kconfig.service", "alice")
          assert machine.succeed("cat /home/alice/.config/kwinrc") == """[Desktops]
          Number=4
          """
        '';
    };
  };
}
