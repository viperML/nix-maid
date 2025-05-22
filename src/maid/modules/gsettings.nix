{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  gsettings-declarative =
    pkgs.python3.pkgs.callPackage ../../../gsettings-declarative/package.nix
      { };

  format = pkgs.formats.json { };
in
{
  options = {
    gsettings = {
      package = mkOption {
        type = types.package;
        description = "The gsettings-declarative package to use.";
        default = gsettings-declarative;
        visible = false;
      };

      settings = mkOption {
        # TODO: Check that it doesn't contain slashes (/)
        type = types.attrsOf (types.attrsOf format.type);
        description = ''
          Attribute set of GSettings. The value can be anything serializable
          to json, as the types are checked at runtime.
        '';
        default = { };
        example = {
          "org.gnome.desktop.interface" = {
            "color-scheme" = "prefer-dark";
            "icon-theme" = "Adwaita";
          };
        };
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
        # TODO: Check that it doesn't contain dots (.), starts with a slash and doens't end with a slash
        type = types.attrsOf format.type;
        default = { };
        description = ''
          Attribute set of Dconf settings. The value can be anything serializable
          to json, as the types are checked at runtime.
        '';
        example = {
          "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
          "/org/gnome/desktop/interface/icon-theme" = "Adwaita";
        };
      };
    };
  };

  config = {
    systemd.services."maid-gsettings" =
      lib.mkIf (config.gsettings.settings != { } || config.dconf.settings != { })
        {
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
