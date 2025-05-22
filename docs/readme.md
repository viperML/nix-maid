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


### Example

Installation for standalone, NixOS module and Flakes in the [Installation section](https://viperml.github.io/nix-maid/installation) of the manual.

The following is an example of a nix-maid configuration. Nix-maid doesn't have its own CLI to install, but rather is installed with Nix itself:

```
$ nix-env -if ./my-config.nix
$ activate
```

```nix
# my-config.nix
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs;
  nix-maid = import sources.nix-maid;
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

## Status

I use nix-maid daily, and I invite you to do so. Currently, only base modules are provided (linking files, defining systemd services), but you
are invited to add high-level modules in a PR (e.g. programs.git).

## Attribution

- Using [sd-switch](https://sr.ht/~rycee/sd-switch/), originally extracted from Home-Manager, to load new systemd units.
- [Hjem](https://github.com/feel-co/hjem) and [Hjem-Rum](https://github.com/snugnug/hjem-rum) do a similar approach with systemd-tmpfiles.
