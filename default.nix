{
  __functor =
    _: pkgsOrSpecialArgs:
    let
      specialArgs =
        if pkgsOrSpecialArgs._type or null == "pkgs" then
          { pkgs = pkgsOrSpecialArgs; }
        else
          pkgsOrSpecialArgs;
    in
    module: ((import ./src/maid specialArgs).eval [ module ]).config.build.bundle;

  nixosModules = {
    default = ./src/nixos;
  };
}
