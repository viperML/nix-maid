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
in
{
  options = {
    systemd = {
      # Upstream dependencies of systemdUtils
      package = mkOption {
        type = types.package;
        default = pkgs.systemd;
      };
      globalEnvironment = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
      enableStrictShellChecks = mkOption {
        type = types.bool;
        default = false;
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
      };
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
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
      inherit (config) units;
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
      ];
      upstreamWants = [ ];
    };

    build.bundle = pkgs.symlinkJoin {
      name = "nix-maid";
      paths = config.packages;
    };
  };
}
