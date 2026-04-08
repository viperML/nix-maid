{
  lib,
  pkgs,
  config,
  ...
}@nixosScope:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    filterAttrs
    ;

  utils = import (pkgs.path + "/nixos/lib/utils.nix");

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

  sharedUser = "nix-maid-shared";
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

      sharedModulesForAllUsers = mkEnableOption "" // {
        description = ''
          Apply nix-maid to all normal users, even if they don't have a personal nix-maid
          configuration, inheriting sharedModules.

          This also applies to users not defined in NixOS, e.g. coming from LDAP.
        '';
      };
    };
  };

  config = {
    users.users.${sharedUser} = lib.mkIf config.maid.sharedModulesForAllUsers {
      isSystemUser = true;
      description = "Placeholder nix-maid user that has a configuration using maid.sharedModules";
      group = "users";
      maid = { };
    };

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

    services.dbus.implementation = "broker";

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
      path = [ pkgs.jq ];
      script = ''
        set +e
        exit_status=0

        while IFS= read -r line; do
          state="$(echo "$line" | jq -r .state)"
          user="$(echo "$line" | jq -r .user)"
          if [[ "$state" = "active" ]]; then
            echo ":: Restarting nix-maid for user $user"
            systemctl try-restart --user --machine "$user@" maid-activation.service
            _e=$?
            if [[ $_e != 0 ]]; then
              exit_status=$_e
            fi
          fi
        done < <(loginctl list-users --json=short | jq -rc '.[]')

        exit "$exit_status"
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
              export "''${line?}"
            fi
          done
        done < <(systemctl --user show-environment 2>/dev/null)

        activation="${config.system.build.all-maid}/nix-maid-$USER/bin/activate"
        if [[ "${builtins.toString config.maid.sharedModulesForAllUsers}" -eq 1 ]] && [[ ! -f "$activation" ]]; then
          activation="${config.system.build.all-maid}/nix-maid-${sharedUser}/bin/activate"
        fi
        echo "Using activation: $activation"
        "$activation"
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
