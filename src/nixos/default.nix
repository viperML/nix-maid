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

  maidModule = types.submoduleWith {
    class = "maid";
    modules = lib.singleton (
      { config, ... }:
      {
        imports = import ../maid/all-modules.nix;
        config._module.args = {
          inherit pkgs;
          # FIXME: If we pass-through nixos' systemdUtils, we get dbus.service in config.build.units
          # inherit (utils) systemdUtils;
          systemdUtils = (utils { inherit config pkgs lib; }).systemdUtils;
        };
      }
    );
  };

  userSubmodule =
    { config, ... }:
    {
      options = {
        maid = mkOption {
          description = "Nix-maid configuration";
          type = types.nullOr maidModule;
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
                #! ${lib.getExe pkgs.bash} -l
                cd "$HOME"
                export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$UID}
                args=()
                systemctl --user is-active init.scope > /dev/null 2>&1
                # If not 0, add -S to args
                if [[ $? != 0 ]]; then
                  args+=(-S)
                fi

                while IFS= read -r line; do
                  for var in DBUS_SESSION_BUS_ADDRESS DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_RUNTIME_DIR; do
                    if [[ "$line" == "$var="* ]]; then
                      export "$line"
                    fi
                  done
                done < <(systemctl --user show-environment 2>/dev/null)

                set -x
                exec "${userConfig.maid.build.bundle}/bin/activate" "''${args[@]}"
              '';
            };
          }
        ];
      }) maidUsers)
    );
  };
}
