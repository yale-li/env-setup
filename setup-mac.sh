#!/usr/bin/env zsh
# setup-mac.sh — Bootstrap a new macOS development machine
# Run: chmod +x setup-mac.sh && ./setup-mac.sh

set -e

# ─────────────────────────────────────────────
# Colors & helpers
# ─────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
BLUE="\033[34m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"

info()    { echo "${BLUE}  →${RESET} $*"; }
success() { echo "${GREEN}  ✓${RESET} $*"; }
warn()    { echo "${YELLOW}  ⚠${RESET} $*"; }
error()   { echo "${RED}  ✗${RESET} $*"; }
header()  { echo "\n${BOLD}${CYAN}$*${RESET}"; }

# Ask yes/no — defaults to yes on Enter
ask() {
  local prompt="$1" default="${2:-y}"
  local hint="[Y/n]"
  [[ "$default" == "n" ]] && hint="[y/N]"
  printf "  ${BOLD}$prompt${RESET} ${DIM}$hint${RESET} "
  read -r reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}

# ─────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────
clear
echo "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║       macOS Dev Environment Setup    ║"
echo "  ╚══════════════════════════════════════╝"
echo "${RESET}"
echo "  This script sets up a fresh macOS machine"
echo "  with your preferred tools and configuration."
echo ""

# ─────────────────────────────────────────────
# Section selection
# ─────────────────────────────────────────────
header "What would you like to install?"
echo ""

ask "Xcode Command Line Tools (required for everything else)" y && DO_XCODE=1 || DO_XCODE=0
ask "Homebrew + formulae (languages, CLI tools)"             y && DO_BREW=1   || DO_BREW=0
ask "GUI apps (Docker Desktop, Chrome, Firefox, IINA…)"     y && DO_CASKS=1  || DO_CASKS=0
ask "Oh My Zsh + plugins"                                    y && DO_ZSH=1    || DO_ZSH=0
ask "Write ~/.zshrc"                                         y && DO_ZSHRC=1  || DO_ZSHRC=0
ask "Git global config"                                      y && DO_GIT=1    || DO_GIT=0
ask "VS Code + extensions"                                   y && DO_VSCODE=1 || DO_VSCODE=0
ask "Claude Code CLI"                                        y && DO_CLAUDE=1 || DO_CLAUDE=0

echo ""
echo "  ${DIM}─────────────────────────────────────────${RESET}"
echo ""

# ─────────────────────────────────────────────
# 1. Xcode Command Line Tools
# ─────────────────────────────────────────────
if [[ $DO_XCODE -eq 1 ]]; then
  header "1. Xcode Command Line Tools"
  if ! xcode-select -p &>/dev/null; then
    info "Launching installer..."
    xcode-select --install
    echo ""
    warn "Re-run this script after the Xcode CLT installation completes."
    exit 1
  else
    success "Already installed."
  fi
fi

# ─────────────────────────────────────────────
# 2. Homebrew + formulae
# ─────────────────────────────────────────────
if [[ $DO_BREW -eq 1 ]]; then
  header "2. Homebrew"
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    success "Homebrew $(brew --version | head -1 | awk '{print $2}') already installed."
  fi

  info "Updating Homebrew..."
  brew update --quiet

  header "3. Homebrew Formulae"

  FORMULAE=(
    # Languages & runtimes
    python@3.14
    node
    go
    deno

    # Python tooling
    pipx
    uv

    # CLI essentials
    git
    gh
    git-lfs
    just
    tmux
    overmind
    fx
    yt-dlp
    ffmpeg
    mkcert
    telnet
    awscli

    # Container / infra
    docker
    docker-compose
    docker-completion
    colima

    # Misc
    hl
    memo
    temporal
  )

  for formula in "${FORMULAE[@]}"; do
    if brew list --formula "$formula" &>/dev/null; then
      success "$formula"
    else
      info "Installing $formula..."
      brew install "$formula"
      success "$formula installed."
    fi
  done
fi

# ─────────────────────────────────────────────
# 4. Casks
# ─────────────────────────────────────────────
if [[ $DO_CASKS -eq 1 ]]; then
  header "4. GUI Apps"

  CASKS=(
    docker-desktop
    google-chrome
    firefox
    iina
    dbeaver-community
    ngrok
  )

  for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
      success "$cask"
    else
      info "Installing $cask..."
      brew install --cask "$cask"
      success "$cask installed."
    fi
  done
fi

# ─────────────────────────────────────────────
# 5. Oh My Zsh
# ─────────────────────────────────────────────
if [[ $DO_ZSH -eq 1 ]]; then
  header "5. Oh My Zsh"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed."
  else
    success "Oh My Zsh already installed."
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "Installing zsh-autosuggestions..."
    git clone -q https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installed."
  else
    success "zsh-autosuggestions already installed."
  fi

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    info "Installing zsh-syntax-highlighting..."
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed."
  else
    success "zsh-syntax-highlighting already installed."
  fi
fi

# ─────────────────────────────────────────────
# 6. ~/.zshrc
# ─────────────────────────────────────────────
if [[ $DO_ZSHRC -eq 1 ]]; then
  header "6. Shell Config (~/.zshrc)"

  if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)"
    info "Existing ~/.zshrc backed up."
  fi

  cat > "$HOME/.zshrc" << 'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
  git
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ── Homebrew ──────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── PATH ──────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Aliases ───────────────────────────────────
alias pip="pip3"

# ── VS Code shell integration ─────────────────
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# ── Docker CLI completions ────────────────────
if [ -d "$HOME/.docker/completions" ]; then
  fpath=($HOME/.docker/completions $fpath)
  autoload -Uz compinit && compinit
fi
ZSHRC

  success "~/.zshrc written."
fi

# ─────────────────────────────────────────────
# 7. Git config
# ─────────────────────────────────────────────
if [[ $DO_GIT -eq 1 ]]; then
  header "7. Git Config"

  printf "  ${BOLD}Your name${RESET} ${DIM}[Yale Li]${RESET}: "
  read -r GIT_NAME
  GIT_NAME="${GIT_NAME:-Yale Li}"

  printf "  ${BOLD}Your email${RESET}: "
  read -r GIT_EMAIL

  git config --global user.name  "$GIT_NAME"
  [[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main
  git config --global pull.rebase true
  git lfs install --skip-smudge 2>/dev/null || true

  success "Git configured for $GIT_NAME${GIT_EMAIL:+ <$GIT_EMAIL>}."
fi

# ─────────────────────────────────────────────
# 8. VS Code + extensions
# ─────────────────────────────────────────────
if [[ $DO_VSCODE -eq 1 ]]; then
  header "8. VS Code"

  if ! command -v code &>/dev/null; then
    info "Installing VS Code..."
    brew install --cask visual-studio-code
  else
    success "VS Code already installed."
  fi

  info "Installing extensions..."

  VSCODE_EXTENSIONS=(
    anthropic.claude-code
    ms-python.python
    ms-python.vscode-pylance
    ms-python.debugpy
    ms-python.vscode-python-envs
    charliermarsh.ruff
    ms-toolsai.jupyter
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
    ms-toolsai.datawrangler
    golang.go
    bradlc.vscode-tailwindcss
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    ritwickdey.liveserver
    redhat.vscode-yaml
    tamasfe.even-better-toml
    mechatroner.rainbow-csv
    qwtel.sqlite-viewer
    mongodb.mongodb-vscode
    boundary.baml-extension
    monokai.theme-monokai-pro-vscode
    pkief.material-icon-theme
    emmanuelbeziat.vscode-great-icons
    llvm-vs-code-extensions.lldb-dap
    swiftlang.swift-vscode
    mathiasfrohlich.kotlin
  )

  for ext in "${VSCODE_EXTENSIONS[@]}"; do
    code --install-extension "$ext" --force &>/dev/null \
      && success "$ext" \
      || warn "Failed: $ext"
  done
fi

# ─────────────────────────────────────────────
# 9. Claude Code CLI
# ─────────────────────────────────────────────
if [[ $DO_CLAUDE -eq 1 ]]; then
  header "9. Claude Code CLI"

  if ! command -v claude &>/dev/null; then
    info "Installing Claude Code (native installer)..."
    curl -fsSL https://claude.ai/install.sh | bash
    success "Claude Code installed."
  else
    success "Claude Code already installed ($(claude --version 2>/dev/null || echo 'unknown version'))."
  fi
fi

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
echo ""
echo "  ${BOLD}${GREEN}✓ All done!${RESET}"
echo ""
echo "  Next steps:"
echo "  ${DIM}1. Restart your terminal  (or: source ~/.zshrc)${RESET}"
echo "  ${DIM}2. Sign in: Docker Desktop, ngrok, gh auth login${RESET}"
echo "  ${DIM}3. Authenticate Claude Code: claude${RESET}"
echo ""
