#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

ok() {
  echo "ok: $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is not installed or not on PATH"
}

ok "checking chezmoi"
require_cmd chezmoi
ok "chezmoi $(chezmoi --version | head -n1)"

diff_output="$(chezmoi diff 2>&1 || true)"
if [[ -n "$diff_output" ]]; then
  printf '%s\n' "$diff_output"
  fail "chezmoi diff is not empty"
fi
ok "chezmoi source and target are in sync"

brew_bin=""
if command -v brew >/dev/null 2>&1; then
  brew_bin="$(command -v brew)"
elif [[ "$OS" == "linux" && -x "$HOME/.linuxbrew/bin/brew" ]]; then
  brew_bin="$HOME/.linuxbrew/bin/brew"
else
  if [[ "$OS" == "linux" ]]; then
    fail "brew is not installed at $HOME/.linuxbrew and not on PATH"
  fi
  fail "brew is not installed or not on PATH"
fi

eval "$("$brew_bin" shellenv)"
ok "brew $("$brew_bin" --version | head -n1)"

"$brew_bin" bundle check --file "$ROOT_DIR/Brewfile" >/dev/null
ok "Brewfile packages are installed"

rendered_zsh="$(mktemp)"
trap 'rm -f "$rendered_zsh" "${rendered_wezterm:-}"' EXIT
chezmoi execute-template -f "$ROOT_DIR/dot_zshrc.tmpl" > "$rendered_zsh"
zsh -n "$rendered_zsh"
ok "zsh template renders cleanly"

if command -v luac >/dev/null 2>&1; then
  rendered_wezterm="$(mktemp)"
  chezmoi execute-template -f "$ROOT_DIR/dot_wezterm.lua.tmpl" > "$rendered_wezterm"
  luac -p "$rendered_wezterm"
  ok "wezterm template renders cleanly"
fi
