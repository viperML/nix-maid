---
title: Installation
---

The following document describes the different ways to install nix-maid. In a nutshell, nix-maid:

- Provides a single bundle package.
- Provides a script `activate` contained in the bundle.
- The user must add bundle to some package list, and run `activate`.

## Standalone

Since this is not run as root, you might need to add `<nixpkgs>`:  
`nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs` (no sudo)  

Using `npins` is recommended to have more control over versions in the standalone variant:

```bash
cd your/nix-maid/config/folder
nix-shell -p npins                            # creates a shell with npins
npins init                                    # initializes npins
npins add github viperML nix-maid -b master   # add nix-maid
                                              # check https://github.com/andir/npins for more
```

```nix
# my-config.nix
let
  pkgs = import <nixpgks> {};
  nix-maid = import (builtins.fetchTarball "https://github.com/viperML/nix-maid/archive/refs/heads/master.tar.gz");
  # Or if you use npins:
  #  sources = import ./npins;
  #  pkgs = import sources.nixpkgs;
  #  nix-maid = import sources.nix-maid;
in
  nix-maid pkgs {
    # nix-maid configuration

    # installs git
    packages = [
      pkgs.git
    ];

    # creates .gitconfig with text
    file.home.".gitconfig".text = ''
      [user]
        name=Maid
    '';

    # creates symlinked folder ~/.config/nvim/ from ~/dotfiles/nvim/ (mind trailing /)
    file.xdg_config."nvim/".source = "{{home}}/dotfiles/nvim/";

    # add that hyprland.conf
    file.xdg_config."hypr/hyprland.conf".source = "{{home}}/dotfiles/hyprland.conf";

    imports = [
      ./my-submodule.nix
    ];
  }
```

Install with:

```
nix-env -if ./my-config.nix
activate
```

## NixOS Module

```nix
# configuration.nix
{ config, pkgs, lib, ... }: let
  nix-maid = import (builtins.fetchTarball "https://github.com/viperML/nix-maid/archive/refs/heads/master.tar.gz") {
  # Or if you use npins:
  #  sources = import ./npins;
  #  nix-maid = import sources.nix-maid;
in {
  imports = [
    nix-maid.nixosModules.default
  ];

  maid.sharedModules = [
    ./some-submodule.nix
  ];
  # ...

  users.users.alice = {
    isNormalUser = true;

    maid = {
      # nix-maid configuration
      packages = [
        pkgs.git
      ];
      file.home.".gitconfig".text = ''
        [user]
          name=Maid
      '';
      imports = [
        ./my-submodule.nix
      ];
    };
  };
}
```

Call `nixos-rebuild switch` normally, no need to do anything else. You can re-trigger the activation with `activate`.

## Standalone + Flakes

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-maid.url = "github:viperML/nix-maid";
  };
  outputs = {self, nixpkgs, nix-maid}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = nix-maid pkgs {
      # nix-maid configuration
      packages = [
        pkgs.git
      ];
      file.home.".gitconfig".text = ''
        [user]
          name=Maid
      '';
      imports = [
        ./my-submodule.nix
      ];
    };
  };
}
```

Install with

```
nix profile install .
activate
```

## NixOS Module + Flakes

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-maid.url = "github:viperML/nix-maid";
  };
  outputs = {self, nixpkgs, nix-maid}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      system = "x86_84-linux";
      modules = [
        ./configuration.nix
        nix-maid.nixosModules.default
      ];
    };
  };
}
```

```nix
# configuration.nix
{ config, pkgs, lib, ... }: {
  # ...

  maid.sharedModules = [
    ./some-submodule.nix
  ];

  users.users.alice = {
    isNormalUser = true;

    maid = {
      # nix-maid configuration
      packages = [
        pkgs.git
      ];
      file.home.".gitconfig".text = ''
        [user]
          name=Maid
      '';
      imports = [
        ./my-submodule.nix
      ];
    };
  };
}
```

Call `nixos-rebuild switch` normally, no need to do anything else. You can re-trigger the activation with `activate`.
