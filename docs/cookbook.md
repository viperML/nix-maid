---
title: Cookbook
---

Examples for using `nix-maid`

These snippets live either in `nix-maid pkgs {}` in a standalone setup, or in `users.users.<username>.maid {};` object when using a module.

## Linking a Directory

```nix
file.xdg_config."nvim/".source = "{{home}}/dotfiles/nvim/";
```

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
```

## KDE Plasma Settings

```nix
```

## Gnome Settings

```nix
org.gnome.shell.extensions.dash-to-panel = {
  "focus-highlight" = true;
  "focus-highlight-dominant" = true;
  "focus-highlight-opacity" = "15";
};
```

Check your current settings with `dconf dump /org/gnome/` and configure as serializable json.
