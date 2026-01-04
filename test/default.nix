let
  pkgs = import <nixpkgs> { };
  maid = (import ../default.nix) pkgs { };
in
maid.config.build.tests
