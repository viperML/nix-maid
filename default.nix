{
  __functor =
    self: pkgs: module:
    ((import ./lib.nix { inherit pkgs; }).eval [ module ]).config.build.bundle;
}
