{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  workProfile = {
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

              [revsets]
              # Only sign commits with my work email
              git-sign-on-push = '~signed() & mine() & author_email(exact-i:"${
                config.sops.placeholder."vcs/user/email"
              }")'
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
  };
  personalProfile =
    let
      user.name = "Guilherme Neubaner";
      user.email = "guilherme.neubaner@gmail.com";
    in
    {
      programs.git = {
        settings = { inherit user; };
      };
      programs.jujutsu = {
        settings = { inherit user; };
      };
    };
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  options = {
    profile = lib.mkOption {
      type = lib.types.enum [
        "work"
        "personal"
      ];
      description = "The homemanager profile";
    };
  };
  config = lib.mkMerge [
    (lib.mkIf (config.profile == "work") workProfile)
    (lib.mkIf (config.profile == "personal") personalProfile)
  ];
}
