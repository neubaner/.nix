final: prev: {
  nerd-fonts = prev.nerd-fonts // {
    iosevka = prev.nerd-fonts.iosevka.overrideAttrs (old: {
      # Only keep the mono version
      postInstall = (old.postInstall or "") + ''
        find "$out/share/fonts" -type f ! -name 'IosevkaNerdFontMono-*.ttf' -delete
      '';
    });
  };
}
