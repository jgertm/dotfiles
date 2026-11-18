# Dotfiles repository instructions

When adding an external dependency that no existing flake input covers, declare
it as a flake input and pin it in `flake.lock` whenever possible.

Always benchmark interactive shell startup time before and after any Zsh configuration change in this repository. Use repeated runs under comparable conditions and report the median times, absolute difference in milliseconds, and percentage change.
