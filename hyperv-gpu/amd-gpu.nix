{ pkgs, lib, ... }:
let
  # GPU-PV looks up the AMD library using the active Windows DriverStore path.
  amdDriverVersion = "32.0.21030.2001";
  amdCabDirectory = "B419765";
  amdLibraries = [
    "amdxc64.so"
    "libamdenc64.so"
  ];
in
{
  driverStorePath = "u0420529.inf_amd64_94ad5a6c4d1a04e2/${amdCabDirectory}";
  graphics =
    pkgs.runCommand "hyperv-amd-graphics-${amdDriverVersion}"
      {
        nativeBuildInputs = [ pkgs.cabextract ];
        amdCab = pkgs.fetchurl {
          url = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2025/12/685e0c6c-01eb-465c-b64a-3b0422280433_dd87edd852abb9957fc9b897a50154b5632bc642.cab";
          hash = "sha256-kqC05JH1S2WA86xjzl2gt2XsjFsWYGTn5UjTF9561KM=";
        };
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        mkdir -p "$out/lib"
        for library in ${lib.escapeShellArgs amdLibraries}; do
          cabextract -p -F "${amdCabDirectory}/$library" "$amdCab" > "$out/lib/$library"
          if [ ! -s "$out/lib/$library" ]; then
            echo "Missing or empty CAB member: ${amdCabDirectory}/$library" >&2
            exit 1
          fi
        done
      '';
}
