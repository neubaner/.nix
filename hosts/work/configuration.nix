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
    };
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.neubaner.imports = [
    ../../home.nix
    inputs.catppuccin.homeModules.catppuccin
    inputs.sops-nix.homeManagerModules.sops
    ({ config, ... }: {
      imports = [ ../../modules/home/vcs.nix ];

      sops = {
        age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
        defaultSopsFile = ../../secrets/work.yaml;
        defaultSopsFormat = "yaml";
        secrets."vcs/user/name" = { };
        secrets."vcs/user/email" = { };

        templates = {
          git-config.content = ''
            [user]
            name = ${config.sops.placeholder."vcs/user/name"}
            email = ${config.sops.placeholder."vcs/user/email"}
          '';

          jujutsu-config = {
            content = ''
              [user]
              name = "${config.sops.placeholder."vcs/user/name"}"
              email = "${config.sops.placeholder."vcs/user/email"}"
            '';
            path = "${config.xdg.configHome}/jj/conf.d/user.toml";
          };
        };
      };

      vcs = {
        enable = true;
        git.includePath = config.sops.templates.git-config.path;
      };
    })
  ];
}
