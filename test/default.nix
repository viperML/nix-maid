let
  pkgs = import <nixpkgs> { };
  maid = (import ../default.nix) pkgs { };
in
{
  all = maid.config.build.allTests;
}
// maid.config.build.tests
