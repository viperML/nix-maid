import <nixpkgs/nixos> {
  configuration =
    { lib, ... }:
    {
      imports = [
        ../src/nixos
      ];

      users.users.alice = {
        isNormalUser = true;
        maid = {
          file.home."foo".source = "/dev/null";
        };
        extraGroups = [ "wheel" ];
      };

      users.users.bob = {
        isNormalUser = true;
      };

      # maid.sharedModules = [
      #   {
      #     file.home."bar".source = "/dev/null";
      #   }
      # ];

      boot.loader.grub.enable = false;
      fileSystems."/".device = "nodev";
      system.stateVersion = lib.trivial.release;
      services.getty.autologinUser = "alice";
      security.sudo.wheelNeedsPassword = false;
    };
}
