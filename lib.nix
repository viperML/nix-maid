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
      modules =
        [
          (
            { config, pkgs, lib, ... }:
            {
              _module.args = {
                systemdUtils = (utils { inherit config pkgs lib; }).systemdUtils;
              };
            }
          )
        ]
        ++ (map (f: ./src/${f}) (builtins.attrNames (builtins.readDir ./src)))
        ++ extraModules;
      specialArgs = {
        inherit pkgs;
      };
    };
}
