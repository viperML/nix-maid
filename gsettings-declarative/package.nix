{
  buildPythonPackage,
  lib,
  setuptools,
  pygobject3,
  colorama,
  wrapGAppsNoGuiHook,
  glib,
  gsettings-desktop-schemas,
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
  buildInputs = [
    glib
    gsettings-desktop-schemas
  ];
  meta.mainProgram = "gsettings-declarative";
}
