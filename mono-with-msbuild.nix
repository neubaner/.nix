# Combines mono and msbuild into a single derivation so that
# Roslyn's MonoMSBuildDiscovery can find MSBuild assemblies by walking
# from the mono binary: realpath(mono) -> ../lib/mono/msbuild/Current/bin/Microsoft.Build.dll
{
  mono,
  msbuild,
  symlinkJoin,
  runCommand,
}:

let
  # First, merge bin/ and lib/ from both mono and msbuild.
  # mono takes priority for everything except lib/mono/msbuild/
  joined = symlinkJoin {
    name = "mono-with-msbuild-joined";
    paths = [
      msbuild # goes first so its msbuild/ wins
      mono
    ];
  };
in
runCommand "mono-with-msbuild" { } ''
  mkdir -p $out

  # Copy the joined tree as symlinks
  cp -rsT ${joined} $out

  # cp -rs preserves read-only directory permissions from the nix store.
  # Make all directories in $out writable so we can modify the symlink forest.
  chmod -R u+w $out

  # The bin/mono symlink currently points into the joined derivation,
  # which itself symlinks to mono's bin/mono. Roslyn calls realpath()
  # which would resolve through all symlinks back to mono's nix store
  # path, defeating the merge. Replace it with a copy so realpath()
  # stops at $out/bin/mono-sgen.
  rm $out/bin/mono-sgen
  cp ${mono}/bin/mono-sgen $out/bin/mono-sgen

  # Ensure bin/mono points to our local mono-sgen
  rm -f $out/bin/mono
  ln -s $out/bin/mono-sgen $out/bin/mono
''
