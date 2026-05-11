# Dotfiles

Personal development environment managed with [chezmoi](https://www.chezmoi.io/).

This repository is set up for cross-platform Unix-like hosts, with bootstrap support for macOS and Ubuntu/Debian. Shell and terminal integrations are guarded so missing tools are skipped instead of breaking startup.

## Stack

- Zsh — primary interactive shell
- Starship — cross-shell prompt
- WezTerm — terminal emulator
- Zellij — terminal multiplexer
- fzf — fuzzy finder
- zoxide — smarter `cd`
- direnv — project environment loading
- mise — language/runtime manager
- Homebrew Bundle — user-level CLI package management
- Gitleaks — pre-commit secret scanning

## Repository layout

chezmoi stores target files with encoded source names:

```text
dot_zshrc.tmpl                         -> ~/.zshrc
dot_wezterm.lua.tmpl                   -> ~/.wezterm.lua
private_dot_config/starship.toml       -> ~/.config/starship.toml
private_dot_config/zellij/config.kdl   -> ~/.config/zellij/config.kdl
Brewfile                               -> package list for Homebrew Bundle
.githooks/pre-commit                   -> Git pre-commit secret scanner
.gitleaks.toml                         -> Gitleaks rules
run_once_before_00-install-base-tools.sh.tmpl
run_onchange_after_10-install-packages.sh.tmpl
run_onchange_after_20-setup-shell.sh.tmpl
bootstrap/bootstrap-macos.sh           -> first-run macOS bootstrap helper
bootstrap/bootstrap-ubuntu.sh          -> first-run Ubuntu/Debian bootstrap helper
```

`private_` means chezmoi applies private permissions to the target path.

## Bootstrap on a new machine

The bootstrap scripts use `DOTFILES_REPO` if set, otherwise they default to `git@github.com:eirenik0/dotfiles.git`.

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/eirenik0/dotfiles/main/bootstrap/bootstrap-macos.sh | bash
```

### Ubuntu / Debian

```bash
curl -fsSL https://raw.githubusercontent.com/eirenik0/dotfiles/main/bootstrap/bootstrap-ubuntu.sh | bash
```

Optional Linuxbrew bootstrap:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing Linuxbrew, re-run:

```bash
chezmoi apply
```

## Daily usage

Edit managed files through chezmoi:

```bash
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
```

Check managed files:

```bash
chezmoi managed
```

Go to the source repo:

```bash
chezmoi cd
```

Update machine from Git:

```bash
chezmoi update
```

## Git workflow

```bash
chezmoi cd
git status
git add .
git commit -m "Update dotfiles"
git push
```

Or through chezmoi:

```bash
chezmoi git status
chezmoi git add .
chezmoi git commit -m "Update dotfiles"
chezmoi git push
```

## Secret scanning

This repository uses Gitleaks in a committed pre-commit hook.

Enable committed hooks in this repo:

```bash
chezmoi cd
git config core.hooksPath .githooks
```

Install Gitleaks:

```bash
brew install gitleaks
```

Manual scan:

```bash
gitleaks detect --source . --redact --verbose
```

Bypass once only when needed:

```bash
SKIP_SECRET_SCAN=1 git commit -m "Commit message"
```

## Do not blindly commit

Be careful with files like:

```text
~/.ssh/config
~/.aws/credentials
~/.docker/config.json
~/.config/gh/hosts.yml
~/.npmrc
~/.pypirc
```

Use templates, encrypted secrets, or a password manager for sensitive files.

## Machine-specific config

The shell and terminal configs use OS and tool guards for optional integrations such as `brew`, `mise`, `direnv`, `jj`, `terraform`, `op`, `starship`, Java, and Android tooling.

Prefer templates instead of separate config files per OS when behavior differs by platform.

Example:

```gotemplate
{{ if eq .chezmoi.os "darwin" }}
# macOS-specific config
{{ end }}

{{ if eq .chezmoi.os "linux" }}
# Linux-specific config
{{ end }}
```

## Provisioning model

This repo uses a layered approach:

```text
1. Bootstrap      — install Git, chezmoi, Homebrew if needed
2. Base packages  — apt/brew dependencies
3. Dotfiles       — zsh/starship/wezterm/zellij/git config
4. Machine logic  — OS/tool guards and local-only settings
```

## Philosophy

This setup is intended to be:

- portable across macOS and Linux where optional tools are installed
- minimal and fast
- safe to apply repeatedly
- compatible with remote development
- optimized for Zsh + Starship + WezTerm + Zellij
