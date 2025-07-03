{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  utils = import (pkgs.path + /nixos/lib/utils.nix);
in
{
  eval =
    extraModules:
    lib.evalModules {
      class = "maid";
      modules =
        [
          (
            {
              config,
              pkgs,
              lib,
              ...
            }:
            {
              _module.args = {
                systemdUtils = (utils { inherit config pkgs lib; }).systemdUtils;
              };
            }
          )
        ]
        ++ (import ./all-modules.nix)
        ++ extraModules;
      specialArgs = {
        inherit pkgs;
      };
    };
}
