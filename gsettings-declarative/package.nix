{
  buildPythonPackage,
  nix-gitignore,
  setuptools,
  pygobject3,
  colorama,
  wrapGAppsNoGuiHook,
  glib,
  gsettings-desktop-schemas,
  gnome-shell,
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
    wrapGAppsNoGuiHook
    glib
  ];
  buildInputs = [
    gsettings-desktop-schemas
    gnome-shell
  ];
  meta.mainProgram = "gsettings-declarative";
}
