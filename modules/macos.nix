{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.copyApps.enable = true;

  home.activation.setMenuBarSpacing = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults -currentHost write -globalDomain NSStatusItemSpacing -int 2
    run /usr/bin/defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 2
  '';
}
