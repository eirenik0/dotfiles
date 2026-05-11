#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/eirenik0/dotfiles.git}"

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew_bin="$(command -v brew 2>/dev/null || true)"
if [[ -z "$brew_bin" && -x /opt/homebrew/bin/brew ]]; then
  brew_bin="/opt/homebrew/bin/brew"
elif [[ -z "$brew_bin" && -x /usr/local/bin/brew ]]; then
  brew_bin="/usr/local/bin/brew"
fi

if [[ -z "$brew_bin" ]]; then
  echo "ERROR: Homebrew was not found after installation."
  exit 1
fi

eval "$("$brew_bin" shellenv)"
"$brew_bin" install git chezmoi

hash -r

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "ERROR: chezmoi was installed, but it is not available on PATH."
  exit 1
fi

chezmoi init --apply "$DOTFILES_REPO"
