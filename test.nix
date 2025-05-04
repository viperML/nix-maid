let
  pkgs = import <nixpkgs> { };
in
(import ./default.nix) pkgs {
  packages = with pkgs; [
    # coreutils
  ];

  systemd.services."test" = {
    script = ''
      pwd
    '';
    serviceConfig.Type = "oneshot";
    wantedBy = [ "default.target" ];
  };
}
