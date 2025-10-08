---
title: Installation
---

Before starting with nix-maid, follow the Nix or NixOS installation guide, and learn some
of it: https://nixos.org/download. Nix-maid supports 2 modes of installation:

- Standalone, for when you are using Nix on top of any other Linux, e.g. Ubuntu.
- NixOS Module, when you control the whole OS of the computer.

On an orthogonal way, you can install nix-maid **without or with flakes**. If you've
just started with Nix, without flakes will be the easier (and what I do for
all my computers).

In case you go flakeless, you can use the tool **npins** (https://github.com/andir/npins) to
automatically pin nix-maid:

```
$ nix-shell -p npins
$ npins init
$ npins add github viperML nix-maid -b master
```


## Standalone

```nix
# my-config.nix
let
  pkgs = import <nixpgks> { };
  nix-maid = import (builtins.fetchTarball "https://github.com/viperML/nix-maid/archive/refs/heads/master.tar.gz") { };

  # Or if you use npins:
  #  sources = import ./npins;
  #  pkgs = import sources.nixpkgs { };
  #  nix-maid = import sources.nix-maid;
in
  nix-maid pkgs {
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
  }
```

Install with:

```
$ nix-env -if ./my-config.nix
$ activate
```


## NixOS Module

```nix
# configuration.nix
{ config, pkgs, lib, ... }: let
  nix-maid = import (builtins.fetchTarball "https://github.com/viperML/nix-maid/archive/refs/heads/master.tar.gz") { };

  # Or if you use npins:
  #  sources = import ./npins;
  #  nix-maid = import sources.nix-maid;
in {
  imports = [
    nix-maid.nixosModules.default
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

  # Maid modules used by all users
  #  For this to take effect, you need at least an empty configuration for a user:
  #  users.users.alice.maid = { };
  maid.sharedModules = [
    ./some-submodule.nix
  ];
}
```

Call `nixos-rebuild switch` normally, no need to do anything else. You can re-trigger the
activation with `systemctl --user restart maid-activation.service`.


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
$ nix profile install .
$ activate
```

## NixOS Module + Flakes

```nix{5,15}
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

  # Maid modules used by all users
  #  For this to take effect, you need at least an empty configuration for a user:
  #  users.users.alice.maid = { };
  maid.sharedModules = [
    ./some-submodule.nix
  ];
}
```

Call `nixos-rebuild switch` normally, no need to do anything else. You can re-trigger the
activation with `systemctl --user restart maid-activation.service`.
