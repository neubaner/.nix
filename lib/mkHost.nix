{
  overlays,
  inputs,
  nixpkgs,
}:
name:
{
  system,
  user,
  wsl ? false,
}:
let
  hostConfig = ../hosts/${name}.nix;
  userOSConfig = ../users/${user}/nixos.nix;
  userHMConfig = ../users/${user}/home-manager.nix;
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
      home-manager.users.${user} = import userHMConfig {
        inherit inputs;
      };
    }
  ];
}
