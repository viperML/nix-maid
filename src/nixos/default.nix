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
    filterAttrs
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
    system.build.all-maid = pkgs.linkFarmFromDrvs "all-maid" (
      builtins.attrValues (
        builtins.mapAttrs (
          user: userConfig:
          userConfig.maid.build.bundle.overrideAttrs (prev: {
            name = "nix-maid-${userConfig.name}";
          })
        ) maidUsers
      )
    );

    systemd.user.services.maid-activation = {
      wantedBy = [ "default.target" ];
      after = [
        "systemd-tmpfiles-setup.service"
        "default.target"
      ];
      script = ''
        while IFS= read -r line; do
          for var in DBUS_SESSION_BUS_ADDRESS DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_RUNTIME_DIR; do
            if [[ "$line" == "$var="* ]]; then
              export "$line"
            fi
          done
        done < <(systemctl --user show-environment 2>/dev/null)

        exec "${config.system.build.all-maid}/nix-maid-$USER/bin/activate"
      '';
      restartTriggers = [ config.system.build.all-maid ];
      restartIfChanged = true;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
