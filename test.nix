let
  pkgs = import <nixpkgs> { };
in
(import ./default.nix) pkgs {
  packages = with pkgs; [
    coreutils
  ];

  systemd.services."test" = {
    script = ''
      pwd
    '';
    serviceConfig.Type = "oneshot";
    wantedBy = [ "default.target" ];
  };

  systemd.tmpfiles.dynamicRules = [
    "f /tmp/nix-maid 0644 {{user}} {{group}} - -"
  ];
}
