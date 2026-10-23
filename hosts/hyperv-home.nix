{
  config,
  pkgs,
  lib,
  currentSystemUser,
  ...
}:
{
  imports = [
    ./hardware/hyperv-home.nix
  ];
  nix = {
    package = pkgs.nixVersions.latest;
    settings.trusted-users = [
      "root"
      currentSystemUser
    ];
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "172.16.0.2";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = {
    address = "172.16.0.1";
    interface = "eth0";
  };
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  services.openssh = {
    enable = true;
    listenAddresses = [
      {
        addr = "0.0.0.0";
      }
    ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
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

  programs.fuse.enable = true;
  services.xserver.enable = true;
  services.xserver.windowManager.dwm.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.xrdp.enable = true;
  services.xrdp.openFirewall = true;
  services.xrdp.defaultWindowManager = toString (
    pkgs.writeShellScript "start-xrdp-dwm" ''
      ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xresources"

      exec ${pkgs.dbus}/bin/dbus-run-session -- \
        ${config.services.xserver.windowManager.dwm.package}/bin/dwm
    ''
  );
  services.xrdp.extraConfDirCommands = ''
    substituteInPlace "$out/xrdp.ini" \
      --replace-fail 'port=3389' 'port=vsock://-1:3389' \
      --replace-fail '#vmconnect=true' 'vmconnect=true'
  '';

  systemd.services.xrdp.serviceConfig.ExecStart =
    lib.mkForce "${pkgs.xrdp}/bin/xrdp --nodaemon --config /etc/xrdp/xrdp.ini";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
