{ inputs, currentSystemUser, ... }:
{
  imports = [
    ./wsl-shared.nix
  ];
  home-manager.users.${currentSystemUser}.imports = [
    inputs.sops-nix.homeManagerModules.sops
    (
      { config, pkgs, ... }:
      {
        sops = {
          age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
          defaultSopsFile = ../secrets/work.yaml;
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
          includes = [ { path = config.sops.templates.git-config.path; } ];
        };

        services.gpg-agent = {
          enable = true;
          enableSshSupport = false;
          pinentry.package = pkgs.pinentry-curses;
        };

        home.packages = [
          pkgs.azure-cli
          pkgs.flyway
          pkgs.grpcurl
          pkgs.terraform
        ];
      }
    )
  ];
}
