---
title: Testing
---

Tests are added by configuring the option `tests.<name>`. This accepts the same argument as `pkgs.nixosTest`. You should configure nix-maid for the `alice` user.

Please check the NixOS tests to get inspiration for writing new tests: https://github.com/NixOS/nixpkgs/tree/master/nixos/tests

Example:

```nix
{ config, pkgs, lib, ... }: {
  options = { /* ... */};

  config = {
    files.home.myapp.text = lib.mkIf (config.myservice.enable) "bar";

    tests.myapp = {
      nodes.machine.users.users.alice.maid = {
        myservice.enable = true;
      };

      testScript = { nodes, ... }: ''
        machine.wait_for_file("/home/alice/myapp")
        assert machine.succeed("cat /home/alice/myapp") == "bar"
      '';
    };
  };
}
```


```
# To run a specific test:
$ nix build -f ./test myapp -L

# To run all tests:
$ nix build -f ./test all -L

# To run an interactive session
$ nix run -f ./test myapp.driverInteractive -L
```
