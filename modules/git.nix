{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    ignores = [ ".DS_Store" ];
    includes = [ { path = "~/.gitconfig.local"; } ];

    settings = {
      # Use the existing gh login for non-interactive HTTPS clones (including T3).
      # Keep gh's own preferences and credential files writable and unmanaged.
      credential."https://github.com".helper = [ "" "${pkgs.gh}/bin/gh auth git-credential" ];
      credential."https://gist.github.com".helper = [ "" "${pkgs.gh}/bin/gh auth git-credential" ];
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase = {
        autoStash = true;
        autoSquash = true;
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      fetch.prune = true;
      merge.conflictStyle = "zdiff3";
      rerere = {
        enabled = true;
        autoUpdate = false;
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "zebra";
      };
      core.editor = config.home.sessionVariables.EDITOR;
      commit.verbose = true;
      branch.sort = "-committerdate";
      user = {
        name = "Tim Jäger";
        email = "6616642+jgertm@users.noreply.github.com";
        useConfigOnly = true;
      };
      alias.root = "rev-parse --show-toplevel";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
