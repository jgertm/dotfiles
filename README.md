# Dotfiles

Nix and Home Manager configuration for Apple Silicon macOS and 64-bit ARM and x86 Linux.

## Install

Clone the repository or extract a release archive. From that directory, run as your regular user.

```sh
./bootstrap --profile home
```

Use `--profile work` on a work machine. Bootstrap installs Nix if needed, enables flakes system-wide, and activates Home Manager. The Nix setup may ask for administrator access. Open a new terminal after activation.

Bootstrap remembers the selected profile on each machine. `./bootstrap` reuses it and defaults to `home` on a fresh system. `./bootstrap --check --profile work` evaluates the work profile without activating or saving it.

## Maintain

- Edit `home.nix` and `modules/` for shared settings. Edit `profiles/home.nix` or `profiles/work.nix` for public settings specific to that context.
- For one machine, add an optional Home Manager module at `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.nix`. Keep credentials outside Nix and outside the checkout.
- After pulling or editing, run `./bootstrap --check` and then `./bootstrap`. In a Git checkout, stage new files before evaluating so the flake can see them.
- To update a branch input, run `nix flake update <input>`. For a versioned release asset, update its URL in `flake.nix` and run `nix flake lock`. Review `flake.lock` before applying.
- On a new machine, set your Git identity in `~/.gitconfig.local` or in each repository.
