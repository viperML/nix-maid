# nix-maid

Systemd + Nix dotfile management.

---

Nix-Maid allows you to configure your dotfiles and systemd services at the user level, similar to Home-Manager.

Nix-Maid is more lightweight and stays closer to the native Nix and systemd (tmpfiles) abstractions.

## Features and Design Choices

- `--lightweight` — Execution is delegated to other tools, making Nix-Maid an almost pure-Nix library.
- `--portable` — Nix-Maid defers the value of your home directory, so the same configuration can be used for different users.
- `--no-legacy` — The API is redesigned from scratch, avoiding past mistakes like `mkOutOfStoreSymlink`.
- `--fast` — Nix-Maid uses a static directory, so cleanups, state files, or traversing the home directory are not needed.

## Documentation

You can find the API documentation here: https://viperml.github.io/nix-maid/api

## Examples

Single user installation, without flakes:

```nix
# nix-maid.nix
let
  pkgs = import <nixpkgs> {};
  nix-maid = import (builtins.fetchTarball "https://github.com/viperML/nix-maid/archive/refs/heads/master.tar.gz");
in
  nix-maid pkgs {
    packages = [
      pkgs.git
    ];
    file.home.".gitconfig".text = ''
      [user]
        name=Maid
    '';
    systemd.services."example" = {
      path = [pkgs.hello];
      script = "hello";
      wantedBy = ["default.target"];
    };
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
      systemd.services."example" = {
        path = [pkgs.hello];
        script = "hello";
        wantedBy = ["default.target"];
      };
    };
  };
}
```

Similarly, this can be installed with:

```
$ nix profile install .
$ activate
```
