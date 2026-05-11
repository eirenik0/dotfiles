#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/eirenik0/dotfiles.git}"

sudo apt update
sudo apt install -y curl git ca-certificates

if ! command -v chezmoi >/dev/null 2>&1; then
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

export PATH="$HOME/.local/bin:$PATH"
hash -r

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "ERROR: chezmoi was installed, but it is not available on PATH."
  echo "Expected the install script to place it in $HOME/.local/bin."
  exit 1
fi

chezmoi init --apply "$DOTFILES_REPO"
