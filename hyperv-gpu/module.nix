{ config, lib, pkgs, ... }:
let
  kernelPackages = config.boot.kernelPackages;
  dxgkrnl = kernelPackages.callPackage ./dxgkrnl.nix { };
in
{
  assertions = [
    {
      assertion = lib.versions.majorMinor kernelPackages.kernel.version == "6.18";
      message = "This dxgkrnl source bundle targets Linux 6.18; review it before changing kernel series.";
    }
    {
      assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
      message = "This dxgkrnl bundle targets x86_64-linux Hyper-V guests.";
    }
  ];
  boot.extraModulePackages = [ dxgkrnl ];
  boot.kernelModules = [ "pci_hyperv" "dxgkrnl" ];
  # Build just this module before rebuilding/activating the system.
  system.build.dxgkrnl = dxgkrnl;
}
