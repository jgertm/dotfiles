{ config, lib, pkgs, ... }:

let
  t3code = pkgs.callPackage ../packages/t3code.nix { };
in
{
  home.packages = [ t3code ];

  # Service and network configuration are outside this module.
  # Desktop appearance is local; pairing and login credentials stay writable.
  home.activation.configureT3Code = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${pkgs.python3}/bin/python3 ${../config/t3code/configure.py} \
        ${lib.escapeShellArg "${config.home.homeDirectory}/.t3/userdata"} \
        ${lib.escapeShellArg config.programs.ghostty.settings.font-family} \
        ${../config/t3code/tokyo-night.json}
    ''
  );
}
