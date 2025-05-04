let
  pkgs = import <nixpkgs> { };
in
(import ../default.nix) pkgs {
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
    # "f /tmp/nix-maid 0644 {{user}} {{group}} - -"
    "f {{xdg_runtime_dir}}/nix-maid 0644 {{user}} {{group}}"
  ];

  # file.home."foo/bar".source = pkgs.coreutils;
  file.home."foo".text = "Hello";
}
