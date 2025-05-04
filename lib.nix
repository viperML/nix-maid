{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}:
let
  utils = import (pkgs.path + /nixos/lib/utils.nix);
in
{
  eval =
    extraModules:
    lib.evalModules {
      modules = [
        (
          { config, ... }:
          {
            _module.args = {
              systemdUtils = (utils { inherit lib config pkgs; }).systemdUtils;
            };
          }
        )
        ./src/core.nix
        ./src/file.nix
        ./src/docs.nix
      ] ++ extraModules;
      specialArgs = {
        inherit pkgs;
      };
    };
}
