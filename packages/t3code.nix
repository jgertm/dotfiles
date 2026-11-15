{ lib, stdenv, stdenvNoCC, fetchurl, unzip, autoPatchelfHook, makeWrapper, zlib, vulkan-loader }:

let
  version = "0.1.9";
  releases = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      sha256 = "7d2eb8c0687b70ca03a9d35498381852d3792983589e82d1fb1831c08f0b2301";
    };
    x86_64-linux = {
      platform = "linux-x64";
      sha256 = "0141025335da334759cecd8db3483e09772f3600ca03674698524e7d94291362";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      sha256 = "52023bc5728a4dee4de361ad6fef7c236f1efb2742ff25e29d5c55e2fb662eea";
    };
  };
  release = releases.${stdenv.hostPlatform.system};
  base = "https://github.com/pingdotgg/t3code/releases/download/v${version}";
  desktop = fetchurl {
    url = "${base}/T3-Code-${version}-arm64.zip";
    sha256 = "03ef426e66ac5b16700188596c1394f448586b8ab7cc379e1e321b29f2c4597e";
  };
in
stdenvNoCC.mkDerivation {
  pname = "t3code";
  inherit version;
  src = fetchurl {
    url = "${base}/t3-${version}-${release.platform}.tar.gz";
    inherit (release) sha256;
  };
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
    unzip -q ${desktop} -d "$out/Applications"
    makeWrapper "$out/Applications/T3 Code (Beta).app/Contents/MacOS/T3 Code (Beta)" \
      "$out/bin/t3code-desktop"
  '' + ''
    runHook postInstall
  '';
  meta = {
    description = "T3 Code desktop and agent server";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    platforms = builtins.attrNames releases;
    mainProgram = "t3";
  };
}
