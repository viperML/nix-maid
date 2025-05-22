{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkMerge
    filterAttrs
    mapAttrsToList
    concatStringsSep
    ;

  utils = import (pkgs.path + /nixos/lib/utils.nix);

  maidModule =
    { config, ... }:
    {
      imports = (import ../maid/all-modules.nix);
      _module.args = {
        inherit pkgs;
        # FIXME: If we pass-through nixos' systemdUtils, we get dbus.service in config.build.units
        # inherit (utils) systemdUtils;

        systemdUtils = (utils { inherit config pkgs lib; }).systemdUtils;
      };
    };

  userSubmodule =
    { config, ... }:
    {
      options = {
        maid = mkOption {
          description = "Nix-maid configuration";
          type = types.nullOr (types.submodule maidModule);
          default = null;
        };
      };

      config = {
        packages = lib.mkIf (config.maid != null) [
          config.maid.build.bundle
        ];
      };
    };

  maidUsers = filterAttrs (user: userConfig: userConfig.maid != null) config.users.users;

  activationUnit = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "nix-daemon.socket" ];
    after = [ "nix-daemon.socket" ];
    before = [ "systemd-user-sessions.service" ];
    stopIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
    };
  };

  # exportedSystemdVariables = concatStringsSep "|" [
  #   "DBUS_SESSION_BUS_ADDRESS"
  #   "DISPLAY"
  #   "WAYLAND_DISPLAY"
  #   "XAUTHORITY"
  #   "XDG_RUNTIME_DIR"
  # ];
in
{
  options = {
    users.users = mkOption {
      type = types.attrsOf (types.submodule userSubmodule);
    };

    maid = {
      # TODO
      # sharedModules = mkOption {
      #   description = "Nix-maid modules to share with all of the users.";
      #   default = [ ];
      #   type = types.listOf (types.submodule maidModule);
      # };
    };
  };

  config = {
    systemd.services = mkMerge (
      [
        {
          "maid-activation@" = activationUnit;
        }
      ]
      ++ (mapAttrsToList (user: userConfig: {
        "maid-activation@${user}" = mkMerge [
          activationUnit
          {
            unitConfig = {
              RequiresMountsFor = userConfig.home;
            };
            serviceConfig = {
              User = user;
              ExecStart = pkgs.writeScript "maid-activation" ''
                #! ${lib.getExe pkgs.bash} -el
                set -eu
                cd "$HOME"
                export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$UID}
                while IFS= read -r line; do
                  eval "export $line"
                done < <(systemctl --user show-environment)
                exec "${userConfig.maid.build.bundle}/bin/activate"
              '';
            };
          }
        ];
      }) maidUsers)
    );
  };
}
