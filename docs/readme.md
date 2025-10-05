<div class="VPHide">
  <h1>nix-maid ❄️🧹</h1>
  <h3>[simpler dotfile management]</h3>
</div>


---


Nix-maid is a library for managing your dotfiles, powered by Nix.
Simple by design, it will make configuring your desktop environment
a breeze. As an alternative to Home-Manager, we throw away many
outdated concepts, making nix-maid the state of the art in dotfile management. Join us into making the desktop experience great again! ❄️🧹

<div class="VPHide">

## Features and Design Choices

- 🪶 Lightweight: The nix-maid core is as lean as possible, pushing the execution to other tools.
- ⚡ Fast: Activation is done as concurrently as possible thanks to systemd.
- 🌐 Portable: Both standalone and as a NixOS module are methods of installation.
- 🚫 No Legacy: New ergonomic API's will make you feel at home.


## Option Documentation

Nix-Maid's options are fully documented: https://viperml.github.io/nix-maid/api. Documentation is top priority for the project.


</div>


### Demo

To get a feel of how nix-maid is used, the following example
shows a standalone nix-maid configuration:

```nix
# my-config.nix
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs;
  nix-maid = import sources.nix-maid;
in

nix-maid pkgs {
  file.home.".gitconfig".text = ''
    [user]
      name=Maid
  '';


  # {{mustache syntax}} resolves at runtime
  # Giving more flexibility and portability across users
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
    org.gnome.mutter.experimental-features = [
      "scale-monitor-framebuffer" "xwayland-native-scaling"
    ];
  };

  dconf.settings = {
    "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
  };

  # Configure KDE Plasma
  kconfig.settings = {
    kwinrc = {
      Desktops.Number = 4;
    };
    baloofilerc = {
      "Basic Settings".Indexing-Enabled = false;
    };
  };
}
```

```
# install and activate:
$ nix-env -if ./my-config.nix
$ activate
```

Nix-maid also supports being installed as a NixOS module, which
is as simple as possible:

```nix
# configuration.nix
{ config, pkgs, ...}: {
  imports = [
    (import (import ./npins).nix-maid).nixosModules.default
  ];

  users.users.alice = {
    isNormalUser = true;
    maid = {
      gsettings.settings = {
        org.gnome.desktop.interface.accent-color = "pink";
      };

      file.home.".gitconfig".text = ''
        [user]
          name=Alice
      '';
    };
  };
}
```


## Novel features

If you like the implementation details, these are some details that we improve on Home-Manager:

- **Static Directory**: when you declare a new file with `file.home`, the symlink will not be direct. Instead, we use a "static directory":
  `~/.gitconfig -> <static>/.gitconfig -> /nix/store/...gitconfig`. This is also done by NixOS for `/etc` and has several advantages:
  - Upgrades are atomic, as we can swap the static directory to the new version, loading all new files at once.
  - Deletions are safer, as we don't have to track files from the older generation. When the new static directory no longer has a file,
    the original will be a dead link.
- **Mustache Syntax**: you can declare elements like `file.home.foo.source = "{{home}}/bar"`. This variable is resolved at activation time. This
  means that your nix-maid configuration doesn't require setting a `home.homeDirectory`, and is easily shareable with other people.
- **file.home behaves correctly**: that is, that it behaves like NixOS's `environment.etc.<name>.source`. If you declare `.source = "string"`,
  nix-maid won't try to coerce it into the nix-store, thus avoiding the non-ergonomic `mkOutOfStoreSymlink` function of home-manager, and all
  the weirdness and bugs that stem from it.
- **No activation hooks by design**: to get the best performance, all the logic is pushed into systemd units, which run concurrently. This makes
  the activation script ultra-fast, as it only has to link the new systemd units and reload the daemon. Unlike home-manager, which pushes a lot
  of logic into `home-manager switch`, which makes it feel sluggish.
