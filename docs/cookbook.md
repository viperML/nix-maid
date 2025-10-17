---
title: Cookbook
---

Examples for using `nix-maid`

These snippets live either in `nix-maid pkgs {}` in a standalone setup, or in `users.users.<username>.maid = {};` object when using a module.

## Install Packages

```nix
packages = with pkgs; [
    git
    nh
    nvd
    (pkgs.writeShellScriptBin "hello" ''
        echo  "hello there!"
    '')
];
```
Does just that.

## Linking Files/Directories

```nix
file.xdg_config."nvim/".source = "{{home}}/dotfiles/nvim/"; 
file.xdg_config."hypr/hyprland.conf".source = "{{home}}/dotfiles/hyprland.conf";
```
`xdg_config` defaults to `~/.config/`. `{{home}}` reads `$HOME`.

## Creating a File/Script

```nix
file.home.".local/bin/hello.sh" = {
  text = ''
    echo Hello $USER
  '';
  executable = true;
};
```
Create an executable script in `~/.local/bin`

```nix
file.xdg_config."fish/conf.d/path-vars.fish" = {
  text = ''
    fish_add_path --global "$HOME/.local/bin"
  '';
};
```
Create `~/.config/fish/conf.d/path-vars.fish` with inline text.

## Creating a systemd user service

```nix
systemd.services.waybar = {
  path = [ pkgs.waybar ];
  script = ''
    exec waybar
  '';
  wantedBy = [ config.maid.systemdGraphicalTarget ];
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

```nix
dconf.settings = {
  "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
  "/org/gnome/desktop/interface/icon-theme" = "Adwaita";
};
```

## Full Example

Install some packages, create a custom script and configure fish shell.

```nix
# my-config.nix
let
  pkgs = import <nixpgks> { };
  nix-maid = import (builtins.fetchTarball "https://github.com/viperML/nix-maid/archive/refs/heads/master.tar.gz") { };
in
nix-maid pkgs {
  packages = with pkgs; [
    nh
    nvd
    (pkgs.writeShellScriptBin "update-os" ''
      echo ":: updating system with $NH_FLAKE"
      nh os switch --update --dry
      read -P ":: check dry-run output and press enter to perform update."
      nh os switch --update
    '')
  ];
  file.xdg_config."fish/conf.d/vars.fish" = {
    text = ''
      # ...
      set -gx NH_FLAKE "$HOME/my-nix-flake"
    '';
  };
}
```

```bash
$ nix-env -if ./my-config.nix
$ activate
```
