{ config, lib, pkgs, t3code, ... }:

{
  home.packages = [ t3code ];

  # Finder and Dock launch the copied, signed app directly.
  launchd.agents.t3code-disable-auto-update = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "/bin/launchctl" "setenv" "T3CODE_DISABLE_AUTO_UPDATE" "1" ];
      RunAtLoad = true;
      LimitLoadToSessionType = "Aqua";
    };
  };

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
