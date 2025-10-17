---
title: Cookbook
---

Examples for using `nix-maid`

These snippets live either in `nix-maid pkgs {}` in a standalone setup, or in `users.users.<username>.maid {};` object when using a module.

## Install Packages

```nix
packages = with pkgs; [
    git
    nh
    nvd
];
```
Does just that.

## Linking Files/Directories

```nix
file.xdg_config."nvim/".source = "{{home}}/dotfiles/nvim/"; # Directories have a trailing /
file.xdg_config."hypr/hyprland.conf".source = "{{home}}/dotfiles/hyprland.conf";
```
Creates links to `~/.config/` (or what ever is set up in xdg).

## Creating a File/Script

```nix
# create executable script in ~
file.home."hello.sh" = {
  text = ''
    echo Hello $USER
  '';
  executable = true;
};
```

## Creating a systemd user service

```nix
systemd.services.waybar = {
  path = [ pkgs.waybar ];
  script = ''
    exec waybar
  '';
  wantedBy = [ "graphical-session.target" ];
};
```

See [API docs](https://viperml.github.io/nix-maid/api.html#systemd-units) for more.  
This might differ from the standard NixOS options.

## KDE Plasma Settings

```nix
kconfig.settings = {
    kwinrc = {
      Desktops.Number = 4;
    };
    baloofilerc = {
      "Basic Settings".Indexing-Enabled = false;
    };
  };
};
```
See [API docs](https://viperml.github.io/nix-maid/api.html#kconfig.settings) and [kconfig-declarative](https://github.com/viperML/kconfig-declarative) for more information.

## Gnome Settings

```nix
org.gnome.desktop.interface = {
    "color-scheme" = "prefer-dark";
    "icon-theme" = "Adwaita";
};
```

Check your current settings with `nix-shell -p dconf --run "dconf dump /org/gnome/"` and configure as serializable json.  

Alternatively [dconf settings](https://viperml.github.io/nix-maid/api.html#dconf.settings) can also be used, but might lead to some nested JSON that needs to be escaped.
