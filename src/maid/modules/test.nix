{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

in
{
  options = {
    tests = mkOption {
      visible = false;
      default = { };
      type = types.attrsOf types.unspecified;
      description = "Attribute set of arguments passed to nixosTest";
    };

    build.tests = mkOption {
      visible = false;
      readOnly = true;
      type = types.attrsOf types.unspecified;
    };

    build.allTests = mkOption {
      visible = false;
      readOnly = true;
      type = types.package;
    };
  };

  config = {
    build.tests = builtins.mapAttrs (
      name:
      { nodes, testScript }:
      pkgs.nixosTest {
        inherit name testScript;
        nodes = builtins.mapAttrs (nodeName: nodeConfig: {
          imports = [
            ../../nixos
            {
              services.getty.autologinUser = "alice";

              users.users.alice = {
                isNormalUser = true;
                description = "Alice Foobar";
                password = "foobar";
                uid = 1000;
                linger = true;
              };

              users.users.bob = {
                isNormalUser = true;
                description = "Bob Foobar";
                password = "foobar";
              };
            }
            nodeConfig
          ];
        }) nodes;
      }
    ) config.tests;

    build.allTests = pkgs.stdenv.mkDerivation {
      name = "nix-maid-tests";
      nativeBuildInputs = [ pkgs.cmake ];
      doCheck = true;
      ctestFlags = "-j1";
      src = pkgs.writeTextDir "CMakeLists.txt" ''
        project(nix-maid-tests)
        cmake_minimum_required(VERSION ${pkgs.cmake.version})
        enable_testing()

        ${lib.concatMapStringsSep "\n" (
          { name, value }:
          ''
            add_test(NAME ${name} COMMAND ${lib.getExe value.driver})
          ''
        ) (lib.attrsToList config.build.tests)}
      '';

      installPhase = ''
        mkdir -p $out
      '';
    };
  };
}
