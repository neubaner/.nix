{ lib, pkgs, ... }:
let
  d3d12 = pkgs.callPackage ./d3d12.nix { };
  amdGpu = pkgs.callPackage ./amd-gpu.nix { };

  gpuRuntime = pkgs.runCommand "hyperv-gpu-runtime" { } ''
    mkdir -p "$out/drivers/${builtins.dirOf amdGpu.driverStorePath}"
    ln -s ${d3d12.graphics}/lib "$out/lib"
    ln -s ${amdGpu.graphics}/lib "$out/drivers/${amdGpu.driverStorePath}"
  '';
  libraryPath = "/run/opengl-driver/lib:/usr/lib/wsl/lib:${
    lib.makeLibraryPath [
      pkgs.stdenv.cc.cc
      pkgs.zlib
      pkgs.openssl
    ]
  }";

  # Shared by the working probes and the xrdp/dwm session startup script.
  gpuEnvironment = pkgs.writeText "hyperv-gpu-session-env.sh" ''
    unset LIBGL_ALWAYS_SOFTWARE LIBGL_ALWAYS_INDIRECT MESA_LOADER_DRIVER_OVERRIDE
    export LD_LIBRARY_PATH="${libraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/dri
    export GALLIUM_DRIVER=d3d12
    export MESA_D3D12_DEFAULT_ADAPTER_NAME=AMD
  '';

  mkGpuProbe =
    name: tool:
    pkgs.writeShellScriptBin name ''
      if [ ! -c /dev/dxg ]; then
        echo '/dev/dxg is missing; check the running kernel, dxgkrnl and GPU attachment.' >&2
        exit 1
      fi
      . ${gpuEnvironment}
      ${lib.optionalString (tool == "eglinfo") ''
        export EGL_PLATFORM=surfaceless
        export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
      ''}
      exec ${pkgs.mesa-demos}/bin/${tool} "$@"
    '';
in
{
  hardware.graphics = {
    enable = true;
    extraPackages = [ d3d12.graphics ];
  };

  # Keep the tmpfiles link stable as the Nix store runtime changes.
  systemd.tmpfiles.rules = [
    "L /usr/lib/wsl - - - - /etc/hyperv-gpu/runtime"
  ];

  system.build = {
    wslGraphics = d3d12.graphics;
    hypervAmdGraphics = amdGpu.graphics;
    hypervGpuRuntime = gpuRuntime;
  };

  environment.etc = {
    "hyperv-gpu/runtime".source = gpuRuntime;
    "hyperv-gpu/session-env.sh".source = gpuEnvironment;
  };

  environment.systemPackages = [
    (mkGpuProbe "hyperv-gpu-glxinfo" "glxinfo")
    (mkGpuProbe "hyperv-gpu-eglinfo" "eglinfo")
  ];
}
