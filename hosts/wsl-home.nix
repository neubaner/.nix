{ currentSystemUser, ... }: {
  imports = [ ./wsl-shared.nix ];

  home-manager.users.${currentSystemUser}.imports = [
    (let
      user.name = "Guilherme Neubaner";
      user.email = "guilherme.neubaner@gmail.com";
    in {
      programs.git = { settings = { inherit user; }; };
      programs.jujutsu = { settings = { inherit user; }; };
    })
  ];
}
