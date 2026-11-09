{ lib, stdenv, fetchurl, kernel }:
let
  # Preserve the exact source/patch revisions used by the working 6.18 build.
  wslRev = "d504d40ab83839cb61942a812a99d183c42227b9";
  staraltRev = "02565c968e19af86d84fe074d9fba8f059af65a2";
  archiveRoot = "WSL2-Linux-Kernel-${wslRev}";
in
stdenv.mkDerivation {
  pname = "dxgkrnl";
  version = "6.18-d504d40-${kernel.version}";

  src = fetchurl {
    name = "wsl-linux-${wslRev}.tar.gz";
    url = "https://codeload.github.com/microsoft/WSL2-Linux-Kernel/tar.gz/${wslRev}";
    hash = "sha256-MsJhD0bpeGrLZNoKGIGISc1v5BZmEtL1IrnMO+GXZWs=";
  };

  # Fetch the original patch unchanged; stdenv applies it during patchPhase.
  patches = [
    (fetchurl {
      name = "dxgkrnl-gpu-pv-support.patch";
      url = "https://raw.githubusercontent.com/staralt/dxgkrnl-dkms/${staraltRev}/linux-msft-wsl-5.15.y/0001-Add-a-gpu-pv-support.patch";
      hash = "sha256-mZTosCE0H3gF9eUaOM0GWrr/jxBrzu/DE4vYWb5Ihls=";
    })
  ];

  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" "format" ];
  dontConfigure = true;
  dontStrip = true;

  # Download the upstream archive once, but unpack only the module and its headers.
  sourceRoot = "source";
  unpackPhase = ''
    runHook preUnpack
    mkdir -p "$sourceRoot"
    tar --extract --gzip --file "$src" \
      --directory "$sourceRoot" --strip-components=1 \
      "${archiveRoot}/drivers/hv/dxgkrnl" \
      "${archiveRoot}/include/uapi/misc/d3dkmthk.h" \
      "${archiveRoot}/LICENSES/preferred/GPL-2.0" \
      "${archiveRoot}/LICENSES/exceptions/Linux-syscall-note"
    runHook postUnpack
  '';

  postPatch = ''
    substituteInPlace drivers/hv/dxgkrnl/Makefile \
      --replace-fail 'obj-$(CONFIG_DXGKRNL)' 'obj-m'
    # Kbuild supplies the configured kernel's source/generated header paths.
    cat >> drivers/hv/dxgkrnl/Makefile <<EOF

ccflags-y += -I$PWD/include -D_MAIN_KERNEL_ -include linux/vmalloc.h
EOF
  '';

  buildPhase = ''
    runHook preBuild
    make -C "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" \
      M="$PWD/drivers/hv/dxgkrnl" \
      ARCH=${stdenv.hostPlatform.linuxArch} \
      CROSS_COMPILE=${stdenv.cc.targetPrefix} \
      -j"$NIX_BUILD_CORES" modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 drivers/hv/dxgkrnl/dxgkrnl.ko \
      "$out/lib/modules/${kernel.modDirVersion}/extra/dxgkrnl.ko"
    install -Dm444 LICENSES/preferred/GPL-2.0 \
      "$out/share/licenses/dxgkrnl/GPL-2.0"
    runHook postInstall
  '';

  meta = {
    description = "Hyper-V GPU-PV module using staralt's patch and WSL 6.18 sources";
    homepage = "https://github.com/staralt/dxgkrnl-dkms";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
