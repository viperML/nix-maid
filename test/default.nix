let
  pkgs = import <nixpkgs> { };
in
(import ../default.nix) pkgs {
  packages = with pkgs; [
    coreutils
  ];

  # systemd.services."test" = {
  #   script = ''
  #     pwd
  #   '';
  #   serviceConfig.Type = "oneshot";
  #   wantedBy = [ "default.target" ];
  # };

  systemd.tmpfiles.dynamicRules = [
    # "f /tmp/nix-maid 0644 {{user}} {{group}} - -"
    "f {{xdg_runtime_dir}}/nix-maid 0644 {{user}} {{group}}"
  ];

  # file.home."foo/bar".source = pkgs.coreutils;
  file.home."foo".text = "Hello";
  file.home."bar".source = "{{home}}";

  gsettings.settings = {
    "org.gnome.desktop.interface" = {
      # "color-scheme" = "prefer-dark";
      "icon-theme" = "Adwaita";
      "clock-format" = 12;
    };
  };

  dconf.settings = {
    "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
  };
}
