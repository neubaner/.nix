{ ... }: {
  home-manager.users.neubaner.imports = [
    (let
      user.name = "Guilherme Neubaner";
      user.email = "guilherme.neubaner@gmail.com";
    in {
      programs.git = {
        userName = user.name;
        userEmail = user.email;
      };

      programs.jujutsu = { settings = { inherit user; }; };
    })
    ({ pkgs, config, ... }: {
      systemd.user.startServices = "sd-switch";
      systemd.user.services.rem-bash = {
        Unit = {
          Description = "A bash server that accepts and execute commands";
          After = [ "network.target" ];
        };
        Install = { WantedBy = [ "default.target" ]; };
        Service = {
          Type = "simple";
          Restart = "always";
          Environment = [
            # To allow calling explorer.exe to open browser links
            "PATH=/mnt/c/Windows/"
          ];
          ExecStart =
            "${pkgs.rem-bash}/bin/rem-bash --host 127.0.0.1 --port 1337";
        };
      };
    })
  ];
}
