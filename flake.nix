{
  description = "My NixOS Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

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
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jujutsu = {
      url = "github:jj-vcs/jj/v0.41.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-opencode-v1_14_48 = {
      url = "github:NixOS/nixpkgs/22a867f12cf98aa49c17d92fdfdff084b888bb7c";
    };

    opencode = {
      url = "github:anomalyco/opencode/v1.14.21";
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
            ];
          nixpkgs.overlays = [
            inputs.jujutsu.overlays.default
            inputs.rem-bash.overlays.default
            # inputs.opencode.overlays.default
            # inputs.neovim-nightly-overlay.overlays.default
            (final: prev: {
              opencode = inputs.nixpkgs-opencode-v1_14_48.legacyPackages.${prev.system}.opencode;
              # neovim = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.neovim;
              # neovim-unwrapped = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.neovim-unwrapped;
              # bun = prev.bun.overrideAttrs (
              #   old:
              #   let
              #     version = "1.3.14";
              #   in
              #   {
              #     inherit version;
              #     # Opencode requires bun 1.3.14
              #     src = prev.fetchurl {
              #       url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
              #       hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
              #     };
              #   }
              # );
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
