{ lib, ...}: let 

  inherit (lib) mkOption types;
in {
  options = {
    maid = {
      systemdTarget = mkOption {
        type = types.str;
        description = "Default target for regular systemd units to start.";
        default = "default.target";
      };

      systemdGraphicalTarget = mkOption {
        type = types.str;
        description = "Default target for graphical systemd units to start.";
        default = "graphical-session.target";
      };
    };
  };
}
