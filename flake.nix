{
  description = "My NixOS Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    rem-bash = {
      url = "github:neubaner/rem-bash";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotnet-8_0_404-nixpkgs.url =
      "github:NixOs/nixpkgs/aa319c6f1e150efc6c21326979d40088c28564a1";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jujutsu = {
      url = "github:jj-vcs/jj/v0.35.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      commonModules = [
        {
          nixpkgs.overlays = [
            inputs.jujutsu.overlays.default
            inputs.rem-bash.overlays.default
            (final: prev: {
              dotnetCorePackages = prev.dotnetCorePackages // {
                combinePackages =
                  inputs.dotnet-8_0_404-nixpkgs.legacyPackages.${prev.system}.dotnetCorePackages.combinePackages;
                sdk_8_0_404 =
                  inputs.dotnet-8_0_404-nixpkgs.legacyPackages.${prev.system}.dotnetCorePackages.sdk_8_0;
              };
            })
          ];
        }
        ./hosts/common.nix
        inputs.nixos-wsl.nixosModules.default
        inputs.catppuccin.nixosModules.catppuccin
        inputs.home-manager.nixosModules.default
      ];
    in {
      nixosConfigurations = {
        work = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            inputs.sops-nix.nixosModules.sops
            ./hosts/work/configuration.nix
          ];
        };
        home = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [ ./hosts/home/configuration.nix ];
        };
      };
    };
}
