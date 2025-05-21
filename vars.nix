{
  home = "$HOME";
  user = "$USER";
  group = "$(id -gn)";
  xdg_config_home = "\${XDG_CONFIG_HOME:-$HOME/.config}";
  xdg_data_home = "\${XDG_DATA_HOME:-$HOME/.local/share}";
  xdg_cache_home = "\${XDG_CACHE_HOME:-$HOME/.cache}";
  xdg_runtime_dir = "\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}";
  xdg_state_home = "\${XDG_STATE_HOME:-$HOME/.local/state}";
}
