{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.copyApps.enable = true;

  home.activation.setMenuBarSpacing = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # On macOS 27, Apple's system icons ignore these preferences even after
    # logging out. Keep them for compact third-party app icons; they cannot
    # make Wi-Fi, battery, clock, Control Center, or input-menu spacing uniform.
    # https://github.com/nlink-jp/menubar-spacer#limits
    run /usr/bin/defaults -currentHost write -globalDomain NSStatusItemSpacing -int 2
    run /usr/bin/defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 2
  '';
}
