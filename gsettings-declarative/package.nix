{
  buildPythonPackage,
  nix-gitignore,
  setuptools,
  pygobject3,
  colorama,
  wrapGAppsHook3,
  glib,
  gobject-introspection,
}:
buildPythonPackage {
  name = "gsettings-declarative";
  src = nix-gitignore.gitignoreSourcePure [ ../.gitignore ] ./.;
  pyproject = true;
  build-system = [
    setuptools
  ];
  dependencies = [
    pygobject3
    colorama
  ];
  nativeBuildInputs = [
    wrapGAppsHook3
    gobject-introspection
  ];
  buildInputs = [
    glib
  ];
  meta.mainProgram = "gsettings-declarative";
}
