{ pkgs, ... }:
{
  nix.package = pkgs.nixVersions.latest;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    builders-use-substitutes = true;

    extra-substituters = [
      "https://neubaner-nix-cache.sfo3.cdn.digitaloceanspaces.com/nix-cache"
    ];

    extra-trusted-public-keys = [
      "neubaner-nix-cache:cOwII4fCtXdZT4ZYGI/M5Fq+NcNy3LIhgmwdKBOmCWg="
    ];

    require-sigs = true;
  };
}
