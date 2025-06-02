<div class="VPHide">
  <h1>nix-maid ❄️🧹</h1>
  <h3>Systemd + Nix dotfile management.</h3>
</div>


---

Nix-Maid allows you to configure your dotfiles and systemd services at the user level, similar to Home-Manager.

Nix-Maid is more lightweight and stays closer to the native Nix, systemd and tmpfiles abstractions.

<div class="VPHide">

## Features and Design Choices

- 🪶 Lightweight: Pushing the execution to other tools, making the project almost a pure-nix library.
- 🌐 Portable: Defers the value of your home directory, so the same configuration works for different users.
- 🚫 No Legacy: API redesigned from scratch, avoiding past mistakes like `mkOutOfStoreSymlink`.
- ⚡ Fast: Uses a static directory, enabling rollbacks without traversing your entire home or diffing profiles.

## Documentation

You can find the API documentation here: https://viperml.github.io/nix-maid/api

</div>


### Example and cool features

Installation for standalone, NixOS module and Flakes in the [Installation section](https://viperml.github.io/nix-maid/installation) of the manual.

The following is an example of a nix-maid configuration. Nix-maid doesn't have its own CLI to install, but rather is installed with Nix itself:


```nix
# my-config.nix
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs;
  nix-maid = import sources.nix-maid;
in
nix-maid pkgs {
  # Add packages to install
  packages = [
    pkgs.yazi
    pkgs.bat
    pkgs.eza
  ];

  # Create files in your home directory
  file.home.".gitconfig".text = ''
    [user]
      name=Maid
  '';

  file.xdg_config."zellij/config.kdl".source = ./config.kdl;

  # `file` supports a mustache syntax, for dynamically resolving the value of {{home}}
  # This same configuration is portable between systems with different home dirs
  file.xdg_config."hypr/hyprland.conf".source = "{{home}}/dotfiles/hyprland.conf";

  # Define systemd-user services, like you would on NixOS
  systemd.services.waybar = {
    path = [ pkgs.waybar ];
    script = ''
      exec waybar
    '';
    wantedBy = [ "graphical-session.target" ];
  };

  # Configure gnome with dconf or gsettings
  gsettings.settings = {
    org.gnome.mutter = {
      experimental-features = [
        "scale-monitor-framebuffer"
        "xwayland-native-scaling"
      ];
      keybindings.cance-input-capture = [ "<Super><Shift>Escape" ];
    };
  };

  dconf.settings = {
    "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
  };

  # Mustache syntax is also available in dynamicRules
  systemd.tmpfiles.dynamicRules = [
    "L {{xdg_config_dir}}/hypr/workspaces.conf - - - - {{home}}/dotfiles/workspaces.conf"
  ];
}
```

```
$ nix-env -if ./my-config.nix
$ activate
```

## Status

I use nix-maid daily, and I invite you to do so. Currently, only base modules are provided (linking files, defining systemd services), but you
are invited to add high-level modules in a PR (e.g. programs.git).

## Attribution

- Using [sd-switch](https://sr.ht/~rycee/sd-switch/), originally extracted from Home-Manager, to load new systemd units.
- [Hjem](https://github.com/feel-co/hjem) and [Hjem-Rum](https://github.com/snugnug/hjem-rum) do a similar approach with systemd-tmpfiles.
