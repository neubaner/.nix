{
  overlays,
  inputs,
  nixpkgs,
}:
name:
{
  system,
  user,
  userProfile ? user,
  wsl ? false,
  hmProfile,
}:
let
  hostConfig = ../hosts/${name}.nix;
  userOSConfig = ../users/${userProfile}/nixos.nix;
  userHMConfig = ../users/${userProfile}/home-manager.nix;
  inherit (nixpkgs.lib) optionals;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs;
    currentSystemUser = user;
    currentSystemName = name;
  };
  modules = [
    {
      nixpkgs = {
        overlays = overlays;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "terraform"
            "1password"
            "1password-cli"
          ];
      };
    }
  ]
  ++ optionals wsl [
    inputs.nixos-wsl.nixosModules.default
  ]
  ++ [
    hostConfig
    userOSConfig
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.${user} = {
        imports = [ userHMConfig ];
        profile = hmProfile;
      };
    }
  ];
}
