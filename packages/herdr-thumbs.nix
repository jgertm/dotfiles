{
  lib,
  stdenvNoCC,
  bash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  ncurses,
  python3,
  thumbs,
  wl-clipboard,
  xclip,
  src,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr-thumbs";
  version = "0.1.0";
  inherit src;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r config scripts herdr-plugin.toml "$out/"
    mkdir -p "$out/vendor/bin"
    ln -s ${lib.getExe' thumbs "thumbs"} "$out/vendor/bin/thumbs"

    substituteInPlace "$out/herdr-plugin.toml" \
      --replace-fail '["bash", ' '["${lib.getExe bash}", '
    for script in pick overlay; do
      substituteInPlace "$out/scripts/$script.sh" \
        --replace-fail '#!/usr/bin/env bash' '#!${lib.getExe bash}
    export PATH=${lib.makeBinPath (
      [ coreutils findutils gnugrep gnused ncurses python3 ]
      ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ wl-clipboard xclip ]
    )}:"$PATH"'
    done
    runHook postInstall
  '';
}
