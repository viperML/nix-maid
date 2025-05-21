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
  manifest = format.generate "manifest.json" {
    version = 1;
    inherit (config.gsettings) settings;
  };
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
    };
  };

  config = {
    systemd.services."maid-gsettings" = {
      wantedBy = [ config.maid.systemdTarget ];
      script = ''
        exec ${lib.getExe config.gsettings.package} ${manifest}
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
