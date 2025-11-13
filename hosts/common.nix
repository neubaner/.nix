{ pkgs, inputs, ... }: {
  wsl.enable = true;
  wsl.defaultUser = "neubaner";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.kernel.sysctl = { "fs.inotify.max_user_instances" = 1024; };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = false;
  users.users.neubaner = {
    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.zsh;
    hashedPassword =
      "$y$j9T$3qwYLr4Ps0KtuAWkImxml1$GawOh8uKn5mS7xDrve79IPRuL7CYUyWymimANSh4Xu.";
  };

  virtualisation.docker.enable = true;

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.neubaner.imports =
    [ inputs.catppuccin.homeModules.catppuccin ../home.nix ];
}
