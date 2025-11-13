{ pkgs, ... }: {
  home.username = "neubaner";
  home.homeDirectory = "/home/neubaner";

  home.packages = [
    # CLI tools
    pkgs.ripgrep
    pkgs.unzip
    pkgs.vectorcode
    pkgs.curl

    # LSPs, formaters and linters
    pkgs.lua-language-server
    pkgs.stylua
    pkgs.jdt-language-server
    pkgs.nil

    # Language support
    pkgs.temurin-bin-21
    pkgs.clang
    pkgs.nodejs
    (with pkgs.dotnetCorePackages; combinePackages [ sdk_8_0 sdk_10_0 ])
  ];

  home.file = {
    # This is mostly to work with jdtls. I build projects in both Java 8 and 21,
    # and having those packages in well-defined location makes it easier to configure
    # jdtls in neovim. Lombok is added as a javaagent to jdtls so it can resolve lombok
    # annotations
    ".jdks/temurin-8".source = pkgs.temurin-bin-8;
    ".jdks/temurin-21".source = pkgs.temurin-bin-21;
    ".jdks/lombok".source = pkgs.lombok;
  };

  home.sessionVariables = { MANPAGER = "nvim +Man!"; };

  # NOTE: The user is configured in the host module
  programs.git.enable = true;
  programs.gh.enable = true;
  programs.jujutsu = {
    enable = true;
    settings = {
      ui.default-command = "log";
      aliases.rebase-trunk =
        [ "rebase" "-s" "needs_rebase()" "-d" "trunk()" "--skip-emptied" ];
      revset-aliases."needs_rebase()" = "roots(trunk()..) & mutable() & mine()";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins = [
      # # Allows zsh to be used with nix-shell
      # {
      #   name = "zsh-nix-shell";
      #   file = "nix-shell.plugin.zsh";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "chisui";
      #     repo = "zsh-nix-shell";
      #     rev = "v0.8.0";
      #     sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
      #   };
      # }
    ];
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
      extraConfig = # sh
        ''
          # Vi mode configuration
          VI_MODE_SET_CURSOR=true

          autoload -U select-quoted
          zle -N select-quoted
          for m in visual viopp; do
              for c in {a,i}{\',\",\`}; do
                  bindkey -M $m $c select-quoted
              done
          done
        '';
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = { add_newline = false; };
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
