# Dotfiles

Nix and Home Manager configuration for Apple Silicon macOS and 64-bit ARM and x86 Linux.

## Install

For a quick install, run this as your regular user with `curl` and `unzip` available. It downloads the current `main` branch to `~/Dropbox/dotfiles`.

```sh
(
  set -eu
  parent="$HOME/Dropbox"
  target="$parent/dotfiles"
  mkdir -p "$parent"
  if [ -e "$target" ] || [ -L "$target" ]; then
    printf 'Already exists: %s\n' "$target" >&2
    exit 1
  fi
  tmp=$(mktemp -d "$parent/.dotfiles-install.XXXXXXXX")
  trap 'rm -rf -- "$tmp"' EXIT
  curl -fsSL https://github.com/jgertm/dotfiles/archive/refs/heads/main.zip -o "$tmp/dotfiles.zip"
  unzip -q "$tmp/dotfiles.zip" -d "$tmp"
  mv "$tmp/dotfiles-main" "$target"
  cd "$target"
  ./bootstrap --profile home
)
```

If you cloned the repository or already extracted an archive, run bootstrap from that directory.

```sh
./bootstrap --profile home
```

Use `--profile work` on a work machine. Bootstrap installs Nix if needed, enables flakes system-wide, and activates Home Manager. The Nix setup may ask for administrator access. Open a new terminal after activation.

Bootstrap remembers the selected profile on each machine. `./bootstrap` reuses it and defaults to `home` on a fresh system. `./bootstrap --check --profile work` evaluates the work profile without activating or saving it.

In Codex, use `/hooks` to review and trust the Herdr session hook.

### Caps Lock → Escape

- **macOS** · Open **System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys**. Choose a keyboard, set **Caps Lock Key** to **Escape**, and repeat for each keyboard you use.
- **Linux** · Bootstrap installs and enables keyd with sudo on systemd-based distributions. On NixOS, add this flake’s `nixosModules.keyd` to your system configuration’s `modules` list and rebuild. On other init systems, install keyd, set `capslock = esc` under `[main]` for all keyboards in `/etc/keyd/default.conf`, and enable the service.

## Maintain

- Edit `home.nix` and `modules/` for shared settings. Edit `profiles/home.nix` or `profiles/work.nix` for public settings specific to that context.
- For one machine, add an optional Home Manager module at `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.nix`. Keep credentials outside Nix and outside the checkout.
- After pulling or editing, run `./bootstrap --check` and then `./bootstrap`. In a Git checkout, stage new files before evaluating so the flake can see them.
- To update a branch input, run `nix flake update <input>`. For a versioned release asset, update its URL in `flake.nix` and run `nix flake lock`. Review `flake.lock` before applying.
- Git defaults to Tim Jäger's GitHub noreply identity. Override it in `~/.gitconfig.local` or in each repository when needed.
