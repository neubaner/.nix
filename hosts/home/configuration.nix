{ inputs, ... }: {
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.neubaner.imports = [
    ../../home.nix
    inputs.catppuccin.homeModules.catppuccin
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
