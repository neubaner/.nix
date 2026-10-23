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
      url = "github:jj-vcs/jj/v0.41.0";
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
        inputs.jujutsu.overlays.default
        (final: prev: {
          opencode = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.opencode;
        })
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
      };
    };
}
