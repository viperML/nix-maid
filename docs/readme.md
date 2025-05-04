# nix-maid

Systemd + Nix dotfile management.

---

Nix-Maid is allows you to configure your dotfiles and systemd services at the User-Level, in a similar way to Home-Managaer.

Nix-Maid is more lightweight, and lives closer to the native Nix and Systemd (tmpfiles) abstractions.

## Features and design choices

- `--lightweight` -- we push the execution to other tools, making Nix-Maid an almost pure-nix library.
- `--portable` -- Nix-Maid defers the value of your home directory, meaning the same configuration can be used with different users.
- `--no-legacy` -- Redesign the API from scratch frees us from past mistakes, like `mkOutOfStoreSymlink`
- `--fast` -- Nix-Maid innovates by using a static directory, meaning rollbacks don't require full $HOME traversal or profile diffing.


## Documentation

You can find the API documentation here: https://viperml.github.io/nix-maid/api


## Examples

Single user installation, without flakes:

```nix
# nix-maid.nix
let
  pkgs = import <nixpkgs> {};
  nix-maid = import (builtins.fetchTarball "https://github.com/viperML/wrapper-manager/archive/refs/heads/master.tar.gz");
in
  nix-maid pkgs {
    packages = [
      pkgs.git
    ];
    file.home.".gitconfig".text = ''
      [user]
        name=Maid
    '';
  }
```

Nix-Maid doesn't have an auto-magic installer tool:

```
$ nix-env -if nix-maid.nix
$ activate
```

---

Single user installation, with flakes:

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
      packages = [
        pkgs.git
      ];
      file.home.".gitconfig".text = ''
        [user]
          name=Maid
      '';
    };
  };
}
```

Similarly, this can be installed with:

```
$ nix profile install .
$ activate
```
