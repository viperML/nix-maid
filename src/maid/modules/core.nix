{
  config,
  systemdUtils,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mapAttrs'
    nameValuePair
    types
    filterAttrs
    concatStringsSep
    mkPackageOption
    literalExpression
    mkEnableOption
    attrsToList
    ;

  inherit (builtins) mapAttrs;

  inherit (systemdUtils.lib)
    generateUnits
    targetToUnit
    serviceToUnit
    sliceToUnit
    socketToUnit
    timerToUnit
    pathToUnit
    ;

  cfg = config.systemd;

  mkImplOption =
    extra:
    mkOption (
      {
        visible = false;
        readOnly = true;
      }
      // extra
    );

  vars = import ../vars.nix;

  vars' = mapAttrs (name: value: "{{${name}}}") vars // {
    hash = ''$(printenv out | sed 's#/nix/store/##g' | cut -d '-' -f 1)'';
  };

  activate = pkgs.writeShellApplication {
    name = "activate";
    inheritPath = false;
    runtimeInputs = [
      pkgs.coreutils
      pkgs.sd-switch
      pkgs.nix
      pkgs.gnugrep
    ];
    text = ''
      while getopts "S" opt; do
        case $opt in
          S) no_sd_switch=1 ;;
          *) echo "Invalid option: -$OPTARG" >&2 ;;
        esac
      done

      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"

      dynamic_tmpfiles="$config_home/user-tmpfiles.d/00-nix-maid-dynamic-tmpfiles.conf"
      static_tmpfiles="$config_home/user-tmpfiles.d/00-nix-maid-tmpfiles.conf"

      old_symlink_array=()
      if [[ -f "$dynamic_tmpfiles" && -f "$static_tmpfiles" ]]; then
        while IFS= read -r line; do
          [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

          IFS=' ' read -r type path _mode _user _group _age _argument <<< "$line"

          [[ "$type" != "L+" ]] && continue

          echo "$path" | grep -q "$state_home/nix-maid/static"  && continue
          echo "$path" | grep -q "$state_home/nix-maid/.*/static" && continue
          old_symlink_array+=("$path")
        done < <(cat "$dynamic_tmpfiles" "$static_tmpfiles")
      fi

      old_symlinks=$(for symlink in "''${old_symlink_array[@]}"; do echo "$symlink"; done | sort)

      echo ":: Loading systemd-tmpfiles"
      mkdir -p "$config_home/systemd"
      mkdir -p "$config_home/user-tmpfiles.d"
      nix-store \
        --realise ${config.build.staticTmpfiles} \
        --add-root "$static_tmpfiles" \
        > /dev/null
      '${lib.getExe config.build.tmpfileRenderer}' > "$dynamic_tmpfiles"
      '${config.systemd.package}/bin/systemd-tmpfiles' --user --create --remove

      new_symlink_array=()
      if [[ -f "$dynamic_tmpfiles" && -f "$static_tmpfiles" ]]; then
        while IFS= read -r line; do
          [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

          IFS=' ' read -r type path _mode _user _group _age _argument <<< "$line"

          [[ "$type" != "L+" ]] && continue

          echo "$path" | grep -q "$state_home/nix-maid/static" && continue
          echo "$path" | grep -q "$state_home/nix-maid/.*/static" && continue
          new_symlink_array+=("$path")
        done < <(cat "$dynamic_tmpfiles" "$static_tmpfiles")
      fi

      new_symlinks=$(for symlink in "''${new_symlink_array[@]}"; do echo "$symlink"; done | sort)

      if [[ "$old_symlinks" != "$new_symlinks" ]]; then
        echo ":: Removing old symlinks"
        for static_path in $(comm -23 <(echo "$old_symlinks") <(echo "$new_symlinks")); do
          if [[ -h "$static_path" ]]; then
            echo ":: Removing $static_path"
            rm "$static_path"
        fi
         done
      fi

      # Init empty array
      sd_switch_flags=()
      # Check if it's a symlink
      if [[ -h "$config_home/systemd/user" ]]; then
        # Check if pointed link exists and is a directory
        if [[ -d "$(realpath "$config_home/systemd/user")" ]]; then
          sd_switch_flags+=("--old-units" "$(realpath "$config_home/systemd/user")")
        fi
      elif [[ -e "$config_home/systemd/user" ]]; then
        rm -rf "$config_home/systemd/user"
      fi

      nix-store \
        --realise ${config.build.units} \
        --add-root "$config_home/systemd/user" \
        > /dev/null

      if [[ -n "''${no_sd_switch:-}" ]]; then
        echo ":: Skipping sd-switch"
      else
        echo ":: Loading systemd units"
        sd-switch --new-units "$config_home/systemd/user" "''${sd_switch_flags[@]}"
      fi
    '';
  };
in
{
  options = {
    systemd = {
      # Upstream dependencies of systemdUtils
      package = mkPackageOption pkgs "systemd" { };
      globalEnvironment = mkOption {
        type =
          with types;
          attrsOf (
            nullOr (oneOf [
              str
              path
              package
            ])
          );
        default = { };
        example = {
          TZ = "CET";
        };
        description = ''
          Environment variables passed to *all* systemd units.
        '';
      };
      packages = mkOption {
        default = [ ];
        type = types.listOf types.package;
        example = literalExpression "[ pkgs.systemd-cryptsetup-generator ]";
        description = "Packages providing systemd units and hooks.";
      };
      enableStrictShellChecks = mkEnableOption "" // {
        description = ''
          Whether to run `shellcheck` on the generated scripts for systemd
          units.

          When enabled, all systemd scripts generated by NixOS will be checked
          with `shellcheck` and any errors or warnings will cause the build to
          fail.

          This affects all scripts that have been created through the `script`,
          `reload`, `preStart`, `postStart`, `preStop` and `postStop` options for
          systemd services. This does not affect command lines passed directly
          to `ExecStart`, `ExecReload`, `ExecStartPre`, `ExecStartPost`,
          `ExecStop` or `ExecStopPost`.

          It therefore also does not affect systemd units that are coming from
          packages and that are not defined through the NixOS config. This option
          is disabled by default, and although some services have already been
          fixed, it is still likely that you will encounter build failures when
          enabling this.

          We encourage people to enable this option when they are willing and
          able to submit fixes for potential build failures to Nixpkgs. The
          option can also be enabled or disabled for individual services using
          the `enableStrictShellChecks` option on the service itself, which will
          take precedence over the global setting.
        '';
      };

      # nix-maid impl
      units = mkOption {
        description = "Definition of systemd per-user units.";
        default = { };
        type = systemdUtils.types.units;
      };

      paths = mkOption {
        default = { };
        type = systemdUtils.types.paths;
        description = "Definition of systemd per-user path units.";
      };

      services = mkOption {
        default = { };
        type = systemdUtils.types.services;
        description = "Definition of systemd per-user service units.";
      };

      slices = mkOption {
        default = { };
        type = systemdUtils.types.slices;
        description = "Definition of systemd per-user slice units.";
      };

      sockets = mkOption {
        default = { };
        type = systemdUtils.types.sockets;
        description = "Definition of systemd per-user socket units.";
      };

      targets = mkOption {
        default = { };
        type = systemdUtils.types.targets;
        description = "Definition of systemd per-user target units.";
      };

      timers = mkOption {
        default = { };
        type = systemdUtils.types.timers;
        description = "Definition of systemd per-user timer units.";
      };

      tmpfiles = {
        rules = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "D %C - - - 7d" ];
          description = ''
            Global user rules for creation, deletion and cleaning of volatile and
            temporary files automatically. See
            {manpage}`tmpfiles.d(5)`
            for the exact format.
          '';
        };

        dynamicRules = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "f {{xdg_runtime_dir}}/test 0644 {{user}} {{group}} - -" ];
          description = ''
            Like tmpfiles.rules, but accepts mustache templates that will be rendered
            at activation time.

            The variables that can be deferred with mustache syntax are the following:
            ```
            ${lib.concatStringsSep "\n" (
              map ({ name, value }: "{{${name}}} -> \"${value}\"") (attrsToList vars)
            )}
            {{hash}} -> "some unique hash"
            ```
          '';
        };
      };
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages to install.";
      example = literalExpression "[ pkgs.git ]";
    };

    build = {
      bundle = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
      };

      units = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
      };

      staticTmpfiles = mkImplOption {
        type = types.package;
      };

      dynamicTmpfiles = mkImplOption {
        type = types.package;
      };

      tmpfileRenderer = mkImplOption {
        type = types.package;
      };
    };
  };

  config = {
    systemd.units =
      mapAttrs' (n: v: nameValuePair "${n}.path" (pathToUnit v)) cfg.paths
      // mapAttrs' (n: v: nameValuePair "${n}.service" (serviceToUnit v)) cfg.services
      // mapAttrs' (n: v: nameValuePair "${n}.slice" (sliceToUnit v)) cfg.slices
      // mapAttrs' (n: v: nameValuePair "${n}.socket" (socketToUnit v)) cfg.sockets
      // mapAttrs' (n: v: nameValuePair "${n}.target" (targetToUnit v)) cfg.targets
      // mapAttrs' (n: v: nameValuePair "${n}.timer" (timerToUnit v)) cfg.timers;

    systemd.timers = mapAttrs (name: service: {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = service.startAt;
    }) (filterAttrs (name: service: service.startAt != [ ]) cfg.services);

    build.units = generateUnits {
      type = "user";
      inherit (config.systemd) units;
      upstreamUnits = [
        # "app.slice"
        # "background.slice"
        # "basic.target"
        # "bluetooth.target"
        # "default.target"
        # "exit.target"
        # "graphical-session-pre.target"
        # "graphical-session.target"
        # "paths.target"
        # "printer.target"
        # "session.slice"
        # "shutdown.target"
        # "smartcard.target"
        # "sockets.target"
        # "sound.target"
        # "systemd-exit.service"
        # "timers.target"
        # "xdg-desktop-autostart.target"
        # "dconf.service"
      ];
      upstreamWants = [ ];
    };

    build.bundle = pkgs.symlinkJoin {
      name = "nix-maid";
      paths = config.packages ++ [
        # config.build.staticTmpfiles
        # config.build.dynamicTmpfiles
        (pkgs.runCommand "nix-maid-units" { } ''
          mkdir -p $out/lib/nix-maid
          ln -sfT ${config.build.units} $out/lib/nix-maid/user-units
        '')
        activate
      ];
      passthru = {
        inherit config;
      };
      meta.mainProgram = "activate";
    };

    build.staticTmpfiles = pkgs.writeText "nix-maid-static-tmpfiles" ''
      ${concatStringsSep "\n" config.systemd.tmpfiles.rules}
    '';

    build.dynamicTmpfiles = pkgs.writeText "nix-maid-dynamic-tmpfiles" ''
      ${concatStringsSep "\n" config.systemd.tmpfiles.dynamicRules}
    '';

    build.tmpfileRenderer =
      pkgs.runCommand "nix-maid-tmpfile-renderer"
        {
          meta.mainProgram = "nix-maid-tmpfile-renderer";
        }
        ''
          set -e
          mkdir -p $out/bin
          tee temp <<EOG
          #! ${pkgs.stdenv.shell}
          set -u
          export PATH="${
            lib.makeBinPath (
              with pkgs;
              [
                coreutils
                mustache-go
              ]
            )
          }"
          mustache ${config.build.dynamicTmpfiles} <<EOF
          ${builtins.toJSON vars'}
          EOF
          EOG

          ${lib.getExe pkgs.mustache-go} temp > $out/bin/nix-maid-tmpfile-renderer <<"EOF"
          ${builtins.toJSON vars}
          EOF

          chmod +x $out/bin/nix-maid-tmpfile-renderer
        '';
  };
}
