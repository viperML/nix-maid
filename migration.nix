''
nix-maid has migrated to Codeberg! You are currently using
the old GitHub input, which will continue to work until October 31st.

To perform the migration, please do the following:

- If you are using npins:

  npins add forgejo codeberg.org viperML nix-maid --branch master

- If you are using flakes:

  sed -i 's#github:viperML/nix-maid#git+https://codeberg.org/viperML/nix-maid#g' ./flake.nix
  nix flake update --flake . nix-maid

- Otherwise:

  sed -i 's#github.com/viperML/nix-maid#codeberg.org/viperML/nix-maid#g'

If you have any issues during the migration, please open a bug report!
https://codeberg.org/viperML/nix-maid/issues
''
