{
  pkgs,
  ...
}:
{
  config = {
    tests.activation-ldap = {
      nodes.machine = {
        users.ldap = {
          enable = true;
          loginPam = false;
          nsswitch = true;
          daemon.enable = true;
          server = "ldap://127.0.0.1";
          base = "dc=example";
        };

        services.openldap = {
          enable = true;
          settings = {
            children = {
              "cn=schema".includes = [
                "${pkgs.openldap}/etc/schema/core.ldif"
                "${pkgs.openldap}/etc/schema/cosine.ldif"
                "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
                "${pkgs.openldap}/etc/schema/nis.ldif"
              ];
              "olcDatabase={1}mdb" = {
                attrs = {
                  objectClass = [
                    "olcDatabaseConfig"
                    "olcMdbConfig"
                  ];
                  olcDatabase = "{1}mdb";
                  olcDbDirectory = "/var/lib/openldap/db";
                  olcSuffix = "dc=example";
                  olcRootDN = "cn=root,dc=example";
                  olcRootPW = "notapassword";
                };
              };
            };
          };
          declarativeContents."dc=example" = ''
            dn: dc=example
            objectClass: domain
            dc: example

            dn: ou=users,dc=example
            objectClass: organizationalUnit
            ou: users

            dn: uid=ldapuser,ou=users,dc=example
            objectClass: inetOrgPerson
            objectClass: posixAccount
            uid: ldapuser
            cn: LDAP User
            sn: User
            uidNumber: 2000
            gidNumber: 100
            homeDirectory: /home/ldapuser
            loginShell: /bin/sh
          '';
        };

        maid.sharedModules = [
          {
            file.home."foo".text = "bar";
          }
        ];

        # Otherwise crashes
        systemd.services.nslcd = {
          after = [ "openldap.service" ];
          wants = [ "openldap.service" ];
        };

        # Automatically create home dir
        security.pam.services.login.makeHomeDir = true;
        security.pam.services.systemd-user.makeHomeDir = true;
      };

      testScript = ''
        machine.wait_for_unit("openldap.service")
        machine.wait_for_unit("nslcd.service")

        machine.succeed("getent passwd ldapuser")
        machine.succeed("loginctl enable-linger ldapuser")

        machine.wait_for_unit("user@2000.service")
        machine.wait_for_unit("maid-system-activation.service")
        machine.wait_for_unit("maid-activation.service", "ldapuser")

        machine.succeed("cat /home/ldapuser/foo")
      '';
    };
  };
}
