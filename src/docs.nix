{
  options,
  pkgs,
  lib,
  ...
}:
{
  options = {
    build.optionsDoc = lib.mkOption {
      type = lib.types.anything;
      readOnly = true;
      visible = false;
    };
  };

  config = {
    build.optionsDoc = pkgs.nixosOptionsDoc {
      inherit options;
    };
  };
}
