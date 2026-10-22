{ pkgs, ... }: {
  users.users.neubaner = {
    isNormalUser = true;
    home = "/home/neubaner";
    extraGroups = [
      "docker"
      "wheel"
    ];
    shell = pkgs.zsh;
    hashedPassword = "$y$j9T$3qwYLr4Ps0KtuAWkImxml1$GawOh8uKn5mS7xDrve79IPRuL7CYUyWymimANSh4Xu.";
  };

  programs.zsh.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = [ pkgs.stdenv.cc.cc.lib ];
  };
}
