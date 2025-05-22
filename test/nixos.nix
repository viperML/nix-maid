import <nixpkgs/nixos> {
  configuration =
    { lib, ... }:
    {
      imports = [
        (import ../.).nixosModules.default
      ];

      users.users.alice = {
        isNormalUser = true;
        maid = {
          file.home."foo".source = "/dev/null";
          systemd.services."test" = {
            script = ''
              pwd
            '';
            serviceConfig.Type = "oneshot";
            wantedBy = [ "default.target" ];
          };
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
