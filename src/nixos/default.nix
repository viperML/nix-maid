{
  lib,
  pkgs,
  config,
  ...
}@nixosScope:
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
        imports = (import ../maid/all-modules.nix) ++ nixosScope.config.maid.sharedModules;
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
      sharedModules = mkOption {
        description = "Nix-maid modules to share with all of the users.";
        default = [ ];
        example = lib.literalExpression "[ ./maid-gnome.nix ]";
        type = types.listOf types.raw;
      };
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

    systemd.services.maid-system-activation = {
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ config.system.build.all-maid ];
      restartIfChanged = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      # enableStrictShellChecks = true;
      description = "System to user activation, workaround for https://github.com/NixOS/nixpkgs/issues/246611";
      script = ''
        for dir in ${config.system.build.all-maid}/*; do
          _basename="$(basename "$dir")"
          USER="''${_basename#nix-maid-}"
          XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
          echo "Checking $USER..."
          if [[ -f "$XDG_RUNTIME_DIR/maid-started" ]]; then
            if systemctl --user --machine "$USER@.host" is-active maid-activation.service; then
              echo "Restarting for $USER"
              systemctl --user --machine "$USER@.host" restart maid-activation.service || :
            fi
          fi
        done
      '';
    };

    systemd.user.services.maid-activation = {
      wantedBy = [
        "default.target"
        "graphical-session-pre.target"
      ];
      before = [ "graphical-session-pre.target" ];
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

        "${config.system.build.all-maid}/nix-maid-$USER/bin/activate"
        touch "$XDG_RUNTIME_DIR/maid-started"
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
