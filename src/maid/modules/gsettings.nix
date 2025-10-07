{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types literalExpression;
  gsettings-declarative =
    pkgs.python3.pkgs.callPackage ../../../gsettings-declarative/package.nix
      { };

  format = pkgs.formats.json { };

  # Recursively check that attribute names don't contain . or /
  gsettingsChecker =
    v:
    if lib.isAttrs v then
      let
        checkAttrName =
          name:
          if lib.hasInfix "." name || lib.hasInfix "/" name then
            throw "GSettings attribute name '${name}' cannot contain '.' or '/' characters, you should use a Nix attribute set."
          else
            true;
        attrNamesValid = lib.all checkAttrName (lib.attrNames v);
        attrValuesValid = lib.all gsettingsChecker (lib.attrValues v);
      in
      attrNamesValid && attrValuesValid
    else
      true;

  # Check that attrnames contain a leading / and don't contain a trailing /
  dconfChecker =
    v:
    let
      hasLeadingSlash = name: lib.hasPrefix "/" name;
      hasTrailingSlash = name: lib.hasSuffix "/" name;
      check =
        name:
        ((hasLeadingSlash name) && (!hasTrailingSlash name))
        || throw "Dconf attribute name '${name}' must start with / and not end with /.";
    in
    lib.all check (lib.attrNames v);
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
        type = types.addCheck format.type gsettingsChecker;
        description = ''
          Attribute set of GSettings. The values can be anything serializable
          to json, as the types are checked at runtime.
        '';
        default = { };
        example = literalExpression ''
          {
            org.gnome.desktop.interface = {
              "color-scheme" = "prefer-dark";
              "icon-theme" = "Adwaita";
            };
          }
        '';
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
        type =
          let
            t = types.attrsOf format.type;
          in
          types.addCheck t dconfChecker;

        default = { };
        description = ''
          Attribute set of Dconf settings. The value can be anything serializable
          to json, as the types are checked at runtime.

          You may want to use gsettings.settings instead, which can be turned into a Nix
          attribute-set.
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
          requires = [ "dconf.service" ];
          script = ''
            exec ${lib.getExe config.gsettings.package} ${config.gsettings.manifest}
          '';
          restartIfChanged = true;
          restartTriggers = [ config.gsettings.manifest ];
          serviceConfig = {
            RemainAfterExit = true;
            Type = "oneshot";
          };
        };

    tests.gsettings = {
      nodes.machine = {
        programs.dconf.enable = true;

        users.users.alice.maid = {
          dconf.settings = {
            "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
          };

          gsettings.settings.org.gnome.desktop.interface.accent-color = "pink";
        };
      };

      testScript =
        { nodes, ... }:
        ''
          machine.wait_for_unit("maid-system-activation.service")
          machine.wait_for_unit("maid-gsettings.service", "alice")
        '';
    };
  };
}
