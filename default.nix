let
  doWarn = false;
  maybeWarn = x: if doWarn then builtins.warn (import ./migration.nix) x else x;
in
maybeWarn {
  __functor =
    self: pkgs: module:
    ((import ./src/maid { inherit pkgs; }).eval [ module ]).config.build.bundle;

  nixosModules = {
    default = ./src/nixos;
  };
}
