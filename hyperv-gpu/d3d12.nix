{ pkgs, lib }:
let
  # This release contains the same three libraries as the working host export.
  wslVersion = "3.0.3";
  direct3dLibraries = [
    "libd3d12.so"
    "libd3d12core.so"
  ];
  # Public WslDependencies feed used by WSL 3.0.3's nuget.config.
  nugetFeed = "https://pkgs.dev.azure.com/shine-oss/13eb32df-d33f-470f-b930-499535a958b4/_packaging/7925a3a1-b93c-4977-8a97-5b877bf2068b/nuget/v3/flat2";
  direct3dVersion = "1.611.1-81528511";
  dxcoreVersion = "10.0.26100.1-240331-1435.ge-release";
in
{
  graphics =
    pkgs.runCommand "hyperv-wsl-graphics-${wslVersion}"
      {
        nativeBuildInputs = [ pkgs.unzip ];
        direct3dPackage = pkgs.fetchurl {
          url = "${nugetFeed}/microsoft.direct3d.linux/${direct3dVersion}/microsoft.direct3d.linux.${direct3dVersion}.nupkg";
          hash = "sha256-Kg4j5LF1XxqcY5pRFQY9sSOtFyEg02Ug/yqpYsUJc/Q=";
        };
        dxcorePackage = pkgs.fetchurl {
          url = "${nugetFeed}/microsoft.dxcore.linux.amd64fre/${dxcoreVersion}/microsoft.dxcore.linux.amd64fre.${dxcoreVersion}.nupkg";
          hash = "sha256-p5rATg6B3dT7ioXsZ5oIVyuInEVT7CVSw9C2RrlQ6dQ=";
        };
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        mkdir -p "$out/lib"
        for library in ${lib.escapeShellArgs direct3dLibraries}; do
          unzip -p "$direct3dPackage" "build/native/lib/x64/$library" > "$out/lib/$library"
        done
        unzip -p "$dxcorePackage" build/native/lib/libDXCore.so > "$out/lib/libdxcore.so"
        ln -s libd3d12core.so "$out/lib/libD3D12Core.so"
      '';
}
