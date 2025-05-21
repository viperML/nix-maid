with import <nixpkgs> { };
mkShell {
  packages = [
    basedpyright
    (python3.withPackages (pp: [
      pp.pygobject3
      pp.pygobject-stubs
      pp.colorama
    ]))
  ];
}
