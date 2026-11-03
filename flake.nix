{
  description = "My NixOS Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jujutsu = {
      url = "github:jj-vcs/jj/v0.46.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      overlays = [
        # The jj overlay does not select the required rust toolchain to build jj
        # inputs.jujutsu.overlays.default
        (final: prev: {
          jujutsu = inputs.jujutsu.packages.${final.stdenv.hostPlatform.system}.default;
        })
        (import ./overlays/iosevka.nix)
        (
          final: prev:
          let
            unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
          in
          {
            opencode = unstable.opencode;
            godot = unstable.godot;
          }
        )
      ];
      mkHost = import ./lib/mkHost.nix { inherit overlays inputs nixpkgs; };
    in
    {
      nixosConfigurations.work = mkHost "wsl-work" {
        system = "x86_64-linux";
        user = "neubaner";
        wsl = true;
      };

      nixosConfigurations.home = mkHost "wsl-home" {
        system = "x86_64-linux";
        user = "neubaner";
        wsl = true;
      };

      nixosConfigurations.hyperv-home = mkHost "hyperv-home" {
        system = "x86_64-linux";
        user = "neubaner";
        userProfile = "gamedev";
      };
    };
}
