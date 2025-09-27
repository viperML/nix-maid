let
  pkgs = import <nixpkgs> { };
in
pkgs.nixos {
  imports = [
    (import ../.).nixosModules.default
    (pkgs.path + /nixos/modules/virtualisation/qemu-vm.nix)
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
    };
    extraGroups = [ "wheel" ];
  };

  virtualisation = {
    graphics = false;
  };

  services.getty.autologinUser = "nixos";
}
