{
  pkgs,
  currentSystemUser,
  ...
}:
{
  wsl = {
    enable = true;
    defaultUser = currentSystemUser;
  };

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  services.openssh = {
    enable = true;
    listenAddresses = [
      {
        addr = "0.0.0.0";
        port = 2222;
      }
    ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      AllowTcpForwarding = "yes";
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  users.mutableUsers = false;

  virtualisation.docker.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
