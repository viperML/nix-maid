# Sample NixOS configuration for development.
# Build with:
# nixos-rebuild build-vm -I nixos-config=./test/nixos.nix
{ config, pkgs, ... }:
{
  imports = [
    (import ../.).nixosModules.default
  ];

  maid.sharedModulesForAllUsers = true;
  maid.sharedModules = [
    {
      file.home.shared-module.source = "/dev/null";
    }
  ];

  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  users.users.nixos = {
    password = "nixos";
    isNormalUser = true;
    maid = {
      imports = [
        {
          file.home.bar.source = "/dev/null";
        }
      ];
      file.home."foo".source = "/dev/null";
      file.xdg_data."foo".text = "bar";
      file.xdg_config."foo".text = "bar";
      systemd.services."test" = {
        script = ''
          pwd
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        wantedBy = [ "default.target" ];

      };
      kconfig.settings = {
        kwinrc = {
          Desktops.Number = 4;
        };
      };
    };
    extraGroups = [ "wheel" ];
  };

  users.users.other = {
    password = "other";
    isNormalUser = true;
  };

  virtualisation.vmVariant = {
    virtualisation.graphics = false;
  };
}
