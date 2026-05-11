#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-git@github.com:eirenik0/dotfiles.git}"

sudo apt update
sudo apt install -y curl git ca-certificates

if ! command -v chezmoi >/dev/null 2>&1; then
    sh -c "$(curl -fsLS get.chezmoi.io)"
    export PATH="$HOME/.local/bin:$PATH"
fi

chezmoi init --apply "$DOTFILES_REPO"
