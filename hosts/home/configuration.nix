{ inputs, ... }: {
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.neubaner.imports = [
    ../../home.nix
    inputs.catppuccin.homeModules.catppuccin
    {
      vcs = {
        enable = true;
        user.name = "Guilherme Neubaner";
        user.email = "guilherme.neubaner@gmail.com";
      };
    }
  ];
}
