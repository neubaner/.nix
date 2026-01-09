{
  description = "My NixOS Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    rem-bash = {
      url = "github:neubaner/rem-bash";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jujutsu = {
      url = "github:jj-vcs/jj/v0.37.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      commonModules = [
        {
          nixpkgs.config.allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "terraform"
              "1password"
              "1password-cli"
              "rider"
            ];
          nixpkgs.overlays = [
            inputs.jujutsu.overlays.default
            inputs.rem-bash.overlays.default
            # inputs.neovim-nightly-overlay.overlays.default
            (final: prev: {
              opencode = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.opencode;
              neovim = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.neovim;
              neovim-unwrapped = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.neovim-unwrapped;
            })
            (final: prev: {
              jetbrains = prev.jetbrains // {
                rider = prev.jetbrains.rider.overrideAttrs (old: {
                  src = prev.fetchurl {
                    url = "https://download.jetbrains.com/rider/JetBrains.Rider-2026.1.0.1.tar.gz";
                    hash = "sha256-moIysTTsq7abpQfNh1Bc5Pk6VQgJIT6erbyHsUXf15Y=";
                  };
                  version = "2026.0.1";
                  autoPatchelfIgnoreMissingDeps = (old.autoPatchelfIgnoreMissingDeps or [ ]) ++ [
                    "libcrypt.so.1"
                    "libssl.so.1.1"
                    "libcrypto.so.1.1"
                  ];
                });
              };
            })
          ];
        }
        ./hosts/common.nix
        inputs.catppuccin.nixosModules.catppuccin
        inputs.home-manager.nixosModules.default
      ];
    in
    {
      nixosConfigurations = {
        work = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            inputs.sops-nix.nixosModules.sops
            inputs.nixos-wsl.nixosModules.default
            ./hosts/work/configuration.nix
          ];
        };
        home = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            inputs.nixos-wsl.nixosModules.default
            ./hosts/home/configuration.nix
          ];
        };
        vm = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            inputs.sops-nix.nixosModules.sops
            (inputs: {
              virtualisation.vmVariant = {
                virtualisation = {
                  memorySize = 2048;
                  cores = 3;
                  graphics = false;
                };
              };
            })
          ];
        };
      };
    };
}
