{
  __functor =
    self: pkgs: module:
    ((import ./src/maid { inherit pkgs; }).eval [ module ]).config.build.bundle;

  nixosModules = {
    default = ./src/nixos;
  };
}
