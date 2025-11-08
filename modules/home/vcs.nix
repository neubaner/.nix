{ config, pkgs, lib, ... }:
let cfg = config.vcs;
in {
  options = {
    vcs.enable =
      lib.mkEnableOption "Enable version control systems (Git and Jujutsu)";
    vcs.user.name = lib.mkOption {
      description = "The user's name";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    vcs.user.email = lib.mkOption {
      description = "The user's email";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    vcs.git.includePath = lib.mkOption {
      description = "The path to a file containing extra configuration for git";
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = cfg.enable;
      userName = lib.mkIf (!isNull cfg.user.name) cfg.user.name;
      userEmail = lib.mkIf (!isNull cfg.user.email) cfg.user.email;
      includes = lib.mkIf (!isNull cfg.git.includePath) [{
        path = cfg.git.includePath;
      }];
    };

    programs.gh.enable = cfg.enable;

    programs.jujutsu = {
      enable = cfg.enable;
      settings = {
        user.name = lib.mkIf (!isNull cfg.user.name) cfg.user.name;
        user.email = lib.mkIf (!isNull cfg.user.email) cfg.user.email;
        ui.default-command = "log";
      };
    };
  };
}
