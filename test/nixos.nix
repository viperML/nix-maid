let
  pkgs = import <nixpkgs> { };
in
pkgs.nixos {
  imports = [
    (import ../.).nixosModules.default
    (pkgs.path + /nixos/modules/virtualisation/qemu-vm.nix)
  ];

  maid.sharedModules = [
    {
      file.home.shared-module.source = "/dev/null";
    }
  ];

  users.users.nixos = {
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

  virtualisation = {
    graphics = false;
  };

  services.getty.autologinUser = "nixos";
}
