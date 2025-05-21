{
  buildPythonPackage,
  lib,
  setuptools,
  pygobject3,
  colorama,
  wrapGAppsNoGuiHook,
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
  nativeBuildInputs = [
    wrapGAppsNoGuiHook
  ];
  meta.mainProgram = "gsettings-declarative";
}
