{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  gsettings-declarative = pkgs.python3.pkgs.callPackage ../gsettings-declarative/package.nix { };

  format = pkgs.formats.json { };
in
{
  options = {
    gsettings = {
      package = mkOption {
        type = types.package;
        description = "The gsettings-declarative package to use.";
        default = gsettings-declarative;
      };

      settings = mkOption {
        type = types.attrsOf (types.attrsOf format.type);
        default = { };
      };

      manifest = mkOption {
        visible = false;
        readOnly = true;
        type = types.package;
        default = format.generate "manifest.json" {
          version = 1;
          inherit (config.gsettings) settings;
          dconf_settings = config.dconf.settings;
        };
      };
    };

    dconf = {
      settings = mkOption {
        type = types.attrsOf format.type;
        default = { };
      };
    };
  };

  config = {
    systemd.services."maid-gsettings" = {
      wantedBy = [ config.maid.systemdTarget ];
      script = ''
        exec ${lib.getExe config.gsettings.package} ${config.gsettings.manifest}
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
