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
        ./module.nix
      ] ++ extraModules;
      specialArgs = {
        inherit pkgs;
      };
    };
}
