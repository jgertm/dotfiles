{
  lib,
  stdenv,
  stdenvNoCC,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  vulkan-loader,
  t3Archive,
  t3DesktopArchive ? null,
}:

stdenvNoCC.mkDerivation {
  pname = "t3code";
  version = "0.1.10";
  src = t3Archive;
  # File inputs can arrive as store paths without an archive extension.
  unpackCmd = ''tar -xzf "$curSrc"'';
  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ unzip ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib zlib vulkan-loader ];
  # The archive also ships musl alternatives; NixOS selects the glibc modules.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" "libc.musl-aarch64.so.1" ];
  dontBuild = true;
  dontStrip = true;
  # Preserve upstream macOS signatures and bundle identity for network privacy.
  dontFixup = stdenv.hostPlatform.isDarwin;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/t3code" "$out/bin"
    cp -R . "$out/libexec/t3code/"
    makeWrapper "$out/libexec/t3code/t3" "$out/bin/t3"
  '' + lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir -p "$out/Applications"
    unzip -q ${t3DesktopArchive} -d "$out/Applications"
    makeWrapper "$out/Applications/T3 Code (Beta).app/Contents/MacOS/T3 Code (Beta)" \
      "$out/bin/t3code-desktop" --set T3CODE_DISABLE_AUTO_UPDATE 1
  '' + ''
    runHook postInstall
  '';
  meta = {
    description = "T3 Code desktop and agent server";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
    mainProgram = "t3";
  };
}
