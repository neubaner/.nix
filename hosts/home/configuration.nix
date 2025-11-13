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
  ];
}
