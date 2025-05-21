{
  buildPythonPackage,
  lib,
  setuptools,
  pygobject3,
  colorama,
}:
buildPythonPackage {
  name = "gsettings-declarative";
  src = lib.cleanSource ./.;
  pyproject = true;
  build-system = [
    setuptools
  ];
  dependencies = [
    pygobject3
    colorama
  ];
  meta.mainProgram = "gsettings-declarative";
}
