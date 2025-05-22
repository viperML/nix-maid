{
  lib,
  pkgs,
  utils,
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
    getExe
    concatStringsSep
    ;

  inherit (builtins) mapAttrs;

  maidModule = {
    imports = (import ../maid/all-modules.nix);
    _module.args = {
      inherit pkgs;
      inherit (utils) systemdUtils;
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

      config = { };
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

  exportedSystemdVariables = concatStringsSep "|" [
    "DBUS_SESSION_BUS_ADDRESS"
    "DISPLAY"
    "WAYLAND_DISPLAY"
    "XAUTHORITY"
    "XDG_RUNTIME_DIR"
  ];
in
{
  options = {
    users.users = mkOption {
      type = types.attrsOf (types.submodule userSubmodule);
    };

    maid = {
      sharedModules = mkOption {
        description = "Nix-maid modules to share with all of the users.";
        default = [ ];
        type = types.listOf (types.submodule maidModule);
      };
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
                set -eux
                cd "$HOME"
                eval "$(
                  systemctl --user show-environment 2> /dev/null \
                  | ${getExe pkgs.gnused} -En '/^(${exportedSystemdVariables})=/s/^/export /p'
                )"
                exec "${userConfig.maid.build.bundle}/bin/activate"
              '';
            };
          }
        ];
      }) maidUsers)
    );

    # users.users = mapAttrs (user: userConfig: {
    #   packages = [
    #     userConfig.maid.config.build.bundle
    #   ];
    # }) maidUsers;
  };
}
