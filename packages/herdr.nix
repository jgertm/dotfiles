{
  lib,
  stdenvNoCC,
  autoPatchelfHook,
  herdrBinary,
}:

let
  inherit (stdenvNoCC) hostPlatform;
in
stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.9.5";

  src = herdrBinary;

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;
  nativeBuildInputs = lib.optional hostPlatform.isLinux autoPatchelfHook;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/herdr"
    runHook postInstall
  '';

  meta = {
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    mainProgram = "herdr";
  };
}
