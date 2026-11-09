{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  efiArch = config.nixpkgs.hostPlatform.efiArch;
in
{
  imports = [ "${modulesPath}/image/repart.nix" ];

  image.repart = {
    name = "hyperv-home";
    imageSize = "20G";
    partitions = {
      "10-esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/Linux/${config.system.boot.loader.ukiFile}".source =
            "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          Label = "ESP";
          SizeMinBytes = "512M";
          SizeMaxBytes = "512M";
        };
      };
      "20-root" = {
        storePaths = [ config.system.build.toplevel ];
        contents."/nix-path-registration".source =
          "${pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; }}/registration";
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "nixos";
        };
      };
    };
  };

  # Register the store paths copied into the image so nix knows about them.
  systemd.services.nix-path-registration = {
    wantedBy = [ "multi-user.target" ];
    before = [ "nix-daemon.service" ];
    unitConfig.ConditionPathExists = "/nix-path-registration";
    serviceConfig.Type = "oneshot";
    script = ''
      ${lib.getExe' config.nix.package.out "nix-store"} --load-db < /nix-path-registration
      rm /nix-path-registration
    '';
  };

  system.build.vhdx =
    pkgs.runCommand "hyperv-home.vhdx"
      {
        nativeBuildInputs = [ pkgs.qemu-utils ];
      }
      ''
        qemu-img convert -f raw -O vhdx -o subformat=dynamic \
          ${config.system.build.image}/${config.image.filePath} $out
      '';
}
