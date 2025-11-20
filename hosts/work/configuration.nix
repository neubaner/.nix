{ inputs, ... }: {
  services.openssh = {
    enable = true;
    listenAddresses = [{
      addr = "0.0.0.0";
      port = 2222;
    }];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      AllowTcpForwarding = "yes";
    };
  };

  home-manager.users.neubaner.imports = [
    inputs.sops-nix.homeManagerModules.sops
    ({ config, pkgs, ... }:
      let
        # I have an small C server running on my home machine that accepts and executes bash commands.
        # The server is proxied to this remote machine via SSH RemoteForward on port 1337.
        # We can then use this server to open any webpage on my home machine by sending a `explorer.exe <url>` command!
        #
        # This makes my experience 100x times better when I use nvim's :GBrowse or I need to authenticate via browser :)
        remoteBrowserScript =
          pkgs.writeShellScriptBin "remote-browser-script" ''
            set -euo pipefail

            if [ $# -eq 0 ]; then
              exit 2
            fi

            for url in "$@"; do
              echo "explorer.exe $url\n" | ${pkgs.netcat}/bin/nc 127.0.0.1 1337
            done
          '';
      in {
        sops = {
          age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
          defaultSopsFile = ../../secrets/work.yaml;
          defaultSopsFormat = "yaml";
          secrets."vcs/user/name" = { };
          secrets."vcs/user/email" = { };

          templates = {
            git-config.content = # gitconfig
              ''
                [user]
                name = ${config.sops.placeholder."vcs/user/name"}
                email = ${config.sops.placeholder."vcs/user/email"}
              '';

            jujutsu-config = {
              content = # toml
                ''
                  [user]
                  name = "${config.sops.placeholder."vcs/user/name"}"
                  email = "${config.sops.placeholder."vcs/user/email"}"
                '';
              path = "${config.xdg.configHome}/jj/conf.d/user.toml";
            };
          };
        };

        programs.git = {
          includes = [{ path = config.sops.templates.git-config.path; }];
        };

        home.sessionVariables = {
          BROWSER = "${remoteBrowserScript}/bin/remote-browser-script";
        };
      })
  ];
}
