{
  config,
  pkgs,
  lib,
  ...
}:
let
  mono-with-msbuild = pkgs.callPackage ./mono-with-msbuild.nix { };
  msbuildPath = "${pkgs.msbuild}/lib/mono/msbuild/Current/bin";
  nuget-restore =
    pkgs.writeShellScriptBin "nuget-restore" # bash
      ''
        exec ${pkgs.nuget}/bin/nuget restore "$@" -MSBuildPath ${msbuildPath}
      '';
in
{
  home.username = "neubaner";
  home.homeDirectory = "/home/neubaner";

  home.packages = [
    # CLI tools
    pkgs.ripgrep
    pkgs.unzip
    pkgs.vectorcode
    pkgs.curl
    pkgs.wget
    pkgs.jq
    pkgs.xdg-utils
    pkgs.icu
    pkgs.tmux-sessionizer
    pkgs.perf
    pkgs.file
    pkgs.lsof
    pkgs.tree
    pkgs.duckdb
    pkgs.bun

    # LSPs, formaters, linters and text editor support
    pkgs.neovim
    pkgs.lua-language-server
    pkgs.stylua
    pkgs.jdt-language-server
    pkgs.nil
    pkgs.nixfmt
    pkgs.clang-tools
    pkgs.lua51Packages.lua
    pkgs.lua51Packages.luarocks
    pkgs.tree-sitter

    # Scala
    pkgs.scala
    pkgs.scala-cli
    pkgs.sbt
    pkgs.coursier
    pkgs.scalafmt

    # Language support
    (lib.hiPrio pkgs.temurin-bin-21)
    pkgs.nodejs
    pkgs.python3
    (lib.hiPrio pkgs.clang)
    pkgs.gcc
    pkgs.gnumake
    pkgs.man-pages
    (
      with pkgs.dotnetCorePackages;
      combinePackages [
        sdk_8_0
        sdk_10_0
      ]
    )
    mono-with-msbuild
    pkgs.nuget
    nuget-restore
  ];

  home.file = {
    # This is mostly to work with jdtls. I build projects in both Java 8 and 21,
    # and having those packages in well-defined location makes it easier to configure
    # jdtls in neovim. Lombok is added as a javaagent to jdtls so it can resolve lombok
    # annotations
    ".jdks/temurin-8".source = pkgs.temurin-bin-8;
    ".jdks/temurin-11".source = pkgs.temurin-bin-11;
    ".jdks/temurin-21".source = pkgs.temurin-bin-21;
    ".jdks/lombok".source = pkgs.lombok;
  };

  home.sessionVariables = {
    MANPAGER = "nvim +Man!";
    DOTNET_ROOT = "${pkgs.dotnetCorePackages.sdk_10_0}/share/dotnet";
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.dotnet/tools"
  ];

  xdg.configFile = {
    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/.config/nvim";
  };

  # NOTE: The user is configured in the host module
  programs.git.enable = true;
  programs.gh.enable = true;
  programs.jujutsu = {
    enable = true;
    settings = {
      ui.default-command = "log";
      aliases.rebase-trunk = [
        "rebase"
        "-s"
        "needs_rebase()"
        "-d"
        "trunk()"
        "--skip-emptied"
      ];
      revset-aliases."needs_rebase()" = "roots(trunk()..) & mutable() & mine()";
    };
  };

  programs.neovim = {
    enable = false;
    defaultEditor = true;

    vimAlias = true;
    vimdiffAlias = true;

    # withPython3 = false;
    # withNodeJs = false;
    # withRuby = false;
  };

  programs.opencode = {
    enable = true;
    settings = {
      autoupdate = true;
      model = "github-copilot/claude-opus-4.6";
      small_model = "github-copilot/claude-sonnet-4.6";
      default_agent = "plan";
      agent = {
        plan = {
          model = "github-copilot/claude-opus-4.6";
        };
        build = {
          model = "github-copilot/claude-sonnet-4.6";
        };
      };
    };
    tui = {
      keybinds = {
        input_newline = "return";
        input_submit = "ctrl+s";
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      vim = "nvim";
      vimdiff = "nvim -d";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "github"
        "rust"
        "dotnet"
        "gradle"
        "github"
        "jj"
        "vi-mode"
        "tmux"
      ];
      extraConfig = # zsh
        ''
          # Vi mode configuration
          VI_MODE_SET_CURSOR=true

          autoload -U select-quoted
          zle -N select-quoted
          for m in visual viopp; do
            for c in a\' i\' a\" i\" a\` i\`; do
                bindkey -M $m $c select-quoted
            done
          done
        '';
    };
    initContent =
      lib.mkAfter # zsh
        ''
          # Keybindings
          autoload -U edit-command-line
          zle -N edit-command-line
          bindkey '\C-e' edit-command-line
        '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
    };
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    terminal = "tmux-256color";

    plugins = [
      pkgs.tmuxPlugins.sensible
      pkgs.tmuxPlugins.yank
      pkgs.tmuxPlugins.cpu
      pkgs.tmuxPlugins.vim-tmux-navigator
      pkgs.tmuxPlugins.weather
    ];

    extraConfig = # tmux
      ''
        # True color
        set-option -sa terminal-overrides ",xterm*:Tc"

        # Options
        set-window-option -g pane-base-index 1
        set-option -g renumber-windows on

        # Shift Control vim keys to switch windows
        bind -n S-Left previous-window
        bind -n S-Right next-window
        bind -n C-S-Left swap-window -t -1\; select-window -t -1
        bind -n C-S-Right swap-window -t +1\; select-window -t +1
      '';
  };

  programs.java = {
    enable = true;
    package = pkgs.temurin-bin-21;
  };

  catppuccin = {
    flavor = "mocha";
    enable = true;
    # Neovim config is not handled by nix
    nvim.enable = false;
    tmux.extraConfig = # tmux
      ''
        set -g @catppuccin_window_status_style "rounded"

        # Display only the base name of the current path the terminal is currently on
        set -g @catppuccin_window_text " #{b:pane_current_path}"
        set -g @catppuccin_window_current_text " #{b:pane_current_path}"

        set -g status-right-length 100
        set -g status-left-length 100
        set -g status-left ""
        set -g status-right "#{E:@catppuccin_status_application}"
        set -agF status-right "#{E:@catppuccin_status_cpu}"
        set -ag status-right "#{E:@catppuccin_status_session}"
        set -agF status-right "#{E:@catppuccin_status_weather}"
        set -ag status-right "#{E:@catppuccin_status_uptime}"
      '';
  };

  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.
}
