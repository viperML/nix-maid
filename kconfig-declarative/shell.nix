with import <nixpkgs> { };
mkShell.override
  {
    stdenv = pkgs.clangStdenv;
  }
  {
    packages = [
      cmake
      qt6.qtbase
      kdePackages.kconfig
      clang-tools
      nlohmann_json
      cli11
      lldb
    ];
    hardeningDisable = [ "all" ];
  }
