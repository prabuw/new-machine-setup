#!/usr/bin/env bash
# =============================================================================
#  macOS Dev Environment Setup Script
#  Installs: Zsh, Homebrew, NVM, Node (latest), pnpm, rbenv, Ruby,
#            Ruby on Rails, Neovim (vim aliased) + LazyVim, Python 3,
#            Docker, GitHub CLI, eza, Raycast, Superwhisper, Arc, Chrome, Spotify,
#            Slack, Notion Calendar, Claude, Codex
#  Copies:   wallpapers/ → ~/Downloads/Wallpaper
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${BLUE}${BOLD}==>${RESET} ${BOLD}$*${RESET}"; }
ok()   { echo -e "${GREEN}✔${RESET}  $*"; }
warn() { echo -e "${YELLOW}⚠${RESET}  $*"; }
die()  { echo -e "${RED}✖${RESET}  $*" >&2; exit 1; }

ZSHRC="$HOME/.zshrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

append_if_missing() {
  local line="$1"
  grep -qxF "$line" "$ZSHRC" 2>/dev/null || echo "$line" >> "$ZSHRC"
}

# ── 0. Require macOS ──────────────────────────────────────────────────────────
[[ "$(uname)" == "Darwin" ]] || die "This script is macOS-only."
touch "$ZSHRC"

# ── 1. Xcode Command Line Tools (provides git, clang, make, etc.) ─────────────
log "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  ok "Xcode CLT already installed at $(xcode-select -p)."
else
  log "Installing Xcode Command Line Tools (non-interactive)…"
  # Trick: touch a sentinel file that makes softwareupdate install CLT silently
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  CLT_PKG=$(softwareupdate -l 2>/dev/null \
    | grep -o 'Command Line Tools for Xcode-[0-9.]*' \
    | sort -V | tail -1)
  if [[ -n "$CLT_PKG" ]]; then
    softwareupdate -i "$CLT_PKG" --verbose
  else
    # Fallback: trigger the GUI installer and wait for it to complete
    warn "Could not find CLT via softwareupdate — triggering GUI installer."
    warn "Please click 'Install' in the dialog that appears, then re-run this script."
    xcode-select --install
    exit 1
  fi
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  ok "Xcode Command Line Tools installed. git version: $(git --version)"
fi

# ── 2. Zsh ───────────────────────────────────────────────────────────────────
log "Zsh"
if [[ "$SHELL" == *zsh ]]; then
  ok "Zsh is already the default shell."
else
  ZSH_PATH="$(command -v zsh || true)"
  if [[ -z "$ZSH_PATH" ]]; then
    warn "zsh not found — will be installed via Homebrew below and set afterwards."
  else
    chsh -s "$ZSH_PATH" && ok "Default shell set to $ZSH_PATH."
  fi
fi

# ── 3. Homebrew ───────────────────────────────────────────────────────────────
log "Homebrew"
if command -v brew &>/dev/null; then
  ok "Homebrew already installed — updating."
  brew update --quiet
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon or Intel
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    append_if_missing 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    append_if_missing 'eval "$(/usr/local/bin/brew shellenv)"'
  fi
  ok "Homebrew installed."
fi

# If zsh wasn't found earlier, set it now that brew is available
if [[ "$SHELL" != *zsh ]]; then
  brew install zsh 2>/dev/null || true
  ZSH_PATH="$(brew --prefix)/bin/zsh"
  grep -qxF "$ZSH_PATH" /etc/shells || sudo sh -c "echo '$ZSH_PATH' >> /etc/shells"
  chsh -s "$ZSH_PATH" && ok "Default shell set to $ZSH_PATH."
fi

# Install desktop apps. Keep manual steps if an installation fails.
MANUAL_APPS=()
install_desktop_app() {
  local cask="$1" app="$2" name="$3" url="$4"
  log "$name"
  if [[ -d "/Applications/$app" || -d "$HOME/Applications/$app" ]]; then
    ok "$name is already installed."
  elif brew list --cask "$cask" &>/dev/null; then
    ok "$name is already installed through Homebrew."
  elif brew install --cask "$cask"; then
    ok "$name installed. Open the app to complete setup."
  else
    warn "$name installation failed. Install it manually: $url"
    MANUAL_APPS+=("$name: $url")
  fi
}

install_desktop_app raycast 'Raycast.app' 'Raycast' 'https://www.raycast.com'
install_desktop_app superwhisper 'superwhisper.app' 'Superwhisper' 'https://superwhisper.com/'
install_desktop_app arc 'Arc.app' 'Arc' 'https://arc.net/'
install_desktop_app google-chrome 'Google Chrome.app' 'Google Chrome' 'https://www.google.com/intl/en_au/chrome'
install_desktop_app spotify 'Spotify.app' 'Spotify' 'https://spotify.com/'
install_desktop_app slack 'Slack.app' 'Slack' 'https://slack.com/downloads/mac'
install_desktop_app notion-calendar 'Notion Calendar.app' 'Notion Calendar' 'https://www.notion.com/product/calendar/download'
install_desktop_app claude 'Claude.app' 'Claude' 'https://claude.com/download'
install_desktop_app codex-app 'Codex.app' 'Codex' 'https://openai.com/codex'

# ── 4. NVM ────────────────────────────────────────────────────────────────────
log "NVM"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR" ]]; then
  ok "NVM directory already exists — skipping install."
else
  NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  ok "NVM ${NVM_VERSION} installed."
fi

NVM_INIT='export NVM_DIR="$HOME/.nvm"'
NVM_LOAD='[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
NVM_COMP='[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
append_if_missing "$NVM_INIT"
append_if_missing "$NVM_LOAD"
append_if_missing "$NVM_COMP"

# Load NVM into current shell session
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# ── 5. Node (latest) ──────────────────────────────────────────────────────────
log "Node.js (latest)"
LATEST_NODE=$(nvm version-remote node 2>/dev/null || true)
CURRENT_NODE=$(nvm current 2>/dev/null || true)
if [[ "$CURRENT_NODE" == "$LATEST_NODE" ]]; then
  ok "Node $CURRENT_NODE is already the latest — skipping."
else
  nvm install node
  nvm alias default node
  ok "Node $(node --version) set as default."
fi

# ── 6. pnpm ───────────────────────────────────────────────────────────────────
log "pnpm"
if command -v pnpm &>/dev/null; then
  ok "pnpm $(pnpm --version) already installed."
else
  npm install -g pnpm
  ok "pnpm $(pnpm --version) installed."
fi

# ── 7. rbenv ─────────────────────────────────────────────────────────────────
log "rbenv"
if command -v rbenv &>/dev/null; then
  ok "rbenv already installed."
else
  brew install rbenv ruby-build
  ok "rbenv installed."
fi
append_if_missing 'eval "$(rbenv init - zsh)"'
eval "$(rbenv init - zsh)" 2>/dev/null || true

# ── 8. Ruby (latest stable) ──────────────────────────────────────────────────
log "Ruby"
RUBY_VERSION=$(rbenv install -l 2>/dev/null | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\s*$' | tail -1 | tr -d ' ')
if rbenv versions | grep -q "$RUBY_VERSION"; then
  ok "Ruby $RUBY_VERSION already installed."
else
  log "Installing Ruby $RUBY_VERSION (this may take a few minutes)…"
  rbenv install "$RUBY_VERSION"
  ok "Ruby $RUBY_VERSION installed."
fi
CURRENT_GLOBAL=$(rbenv global 2>/dev/null || true)
if [[ "$CURRENT_GLOBAL" == "$RUBY_VERSION" ]]; then
  ok "Ruby $RUBY_VERSION already set as global."
else
  rbenv global "$RUBY_VERSION"
  ok "Ruby $(ruby --version) set as global."
fi

# ── 9. Ruby on Rails ─────────────────────────────────────────────────────────
log "Ruby on Rails"
if gem list rails -i &>/dev/null; then
  ok "Rails $(rails --version) already installed."
else
  gem install rails --no-document
  rbenv rehash
  ok "Rails $(rails --version) installed."
fi

# ── 10. Neovim + vim alias + LazyVim ─────────────────────────────────────────
log "Neovim"
if command -v nvim &>/dev/null; then
  ok "Neovim $(nvim --version | head -1) already installed."
else
  brew install neovim
  ok "Neovim $(nvim --version | head -1) installed."
fi
append_if_missing 'alias vim="nvim"'
ok "'vim' aliased to 'nvim' in ~/.zshrc."

log "LazyVim"
NVIM_CONFIG="$HOME/.config/nvim"
if [[ -d "$NVIM_CONFIG" && -f "$NVIM_CONFIG/lua/config/lazy.lua" ]]; then
  ok "LazyVim already configured at $NVIM_CONFIG."
else
  # Back up any existing config
  if [[ -d "$NVIM_CONFIG" ]]; then
    warn "Existing nvim config found — backing up to ~/.config/nvim.bak"
    mv "$NVIM_CONFIG" "${NVIM_CONFIG}.bak"
  fi
  # LazyVim deps (lazygit, fd already useful standalone; ripgrep may be installed already)
  for dep in lazygit fd ripgrep; do
    command -v "$dep" &>/dev/null || brew install "$dep"
  done
  # Clone the LazyVim starter
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
  # Remove the .git dir so you own the config from here
  rm -rf "$NVIM_CONFIG/.git"
  ok "LazyVim starter cloned to $NVIM_CONFIG."
  warn "Run 'nvim' once to let LazyVim bootstrap all plugins."
fi

# ── 11. Python 3 ─────────────────────────────────────────────────────────────
log "Python 3"
if command -v python3 &>/dev/null && python3 --version 2>&1 | grep -q "Python 3"; then
  ok "Python $(python3 --version) already installed."
else
  brew install python
  ok "Python $(python3 --version) installed."
fi
# Ensure pip3 is up to date (only if outdated)
if python3 -m pip install --upgrade pip --quiet --dry-run 2>/dev/null | grep -q "Would install"; then
  python3 -m pip install --upgrade pip --quiet
  ok "pip3 upgraded."
else
  ok "pip3 already up to date."
fi
# Convenient alias: 'python' → 'python3'
append_if_missing 'alias python="python3"'
append_if_missing 'alias pip="pip3"'
ok "'python' and 'pip' aliased to python3/pip3 in ~/.zshrc."

# ── 12. bat (cat replacement) ────────────────────────────────────────────────
log "bat"
if command -v bat &>/dev/null; then
  ok "bat $(bat --version) already installed."
else
  brew install bat
  ok "bat $(bat --version) installed."
fi
append_if_missing 'alias cat="bat --paging=never"'
ok "'cat' aliased to 'bat --paging=never' in ~/.zshrc."

# ── 13. ripgrep (grep replacement) ───────────────────────────────────────────
log "ripgrep"
if command -v rg &>/dev/null; then
  ok "ripgrep $(rg --version | head -1) already installed."
else
  # May already be installed as a LazyVim dep — brew is idempotent
  brew install ripgrep
  ok "ripgrep $(rg --version | head -1) installed."
fi
append_if_missing 'alias grep="rg"'
ok "'grep' aliased to 'rg' in ~/.zshrc."

# Install eza.
log "eza"
if command -v eza &>/dev/null; then
  ok "eza is already installed."
elif brew install eza; then
  ok "eza installed. Run 'eza' to list files."
else
  warn "eza installation failed. Retry with: brew install eza"
  warn "Manual installation: https://github.com/eza-community/eza/blob/main/INSTALL.md"
  MANUAL_APPS+=("eza: https://github.com/eza-community/eza/blob/main/INSTALL.md")
fi

# ── 14. Claude Code ──────────────────────────────────────────────────────────
log "Claude Code"
if command -v claude &>/dev/null; then
  ok "Claude Code $(claude --version 2>/dev/null | head -1) already installed."
else
  curl -fsSL https://claude.ai/install.sh | bash
  ok "Claude Code installed. Run 'claude' in any project directory to start."
  warn "You'll be prompted to authenticate with your Anthropic account on first run."
fi

# ── 15. OpenCode ──────────────────────────────────────────────────────────────
log "OpenCode"
if command -v opencode &>/dev/null; then
  ok "OpenCode already installed."
else
  curl -fsSL https://opencode.ai/install | bash
  ok "OpenCode installed."
  warn "Run 'opencode' in a project directory and use /connect to set up your LLM provider."
fi

# ── 16. Shottr ───────────────────────────────────────────────────────────────
log "Shottr"
if [[ -d "/Applications/Shottr.app" ]]; then
  ok "Shottr already installed."
else
  brew install --cask shottr
  ok "Shottr installed. Open it from /Applications to grant screen recording permission."
fi

# ── 17. Starship ──────────────────────────────────────────────────────────────
log "Starship"
if command -v starship &>/dev/null; then
  ok "Starship $(starship --version | head -1) already installed."
else
  brew install starship
  ok "Starship installed."
fi
# Init line must be last in .zshrc to take effect — check and append
append_if_missing 'eval "$(starship init zsh)"'
# Apply Catppuccin Powerline preset
STARSHIP_CFG="$HOME/.config/starship.toml"
if [[ -f "$STARSHIP_CFG" ]]; then
  ok "Starship config already exists at $STARSHIP_CFG — skipping preset."
else
  mkdir -p "$HOME/.config"
  starship preset catppuccin-powerline -o "$STARSHIP_CFG"
  ok "Catppuccin Powerline preset written to $STARSHIP_CFG."
fi

# ── 18. Docker ───────────────────────────────────────────────────────────────
log "Docker"
if command -v docker &>/dev/null; then
  ok "Docker $(docker --version) already installed."
else
  brew install --cask docker
  ok "Docker Desktop installed. Open it from /Applications to complete setup."
  warn "Docker Desktop requires a manual first-launch to start the daemon."
fi

# ── 19. GitHub CLI ────────────────────────────────────────────────────────────
log "GitHub CLI"
if command -v gh &>/dev/null; then
  ok "GitHub CLI $(gh --version | head -1) already installed."
else
  brew install gh
  ok "GitHub CLI $(gh --version | head -1) installed."
fi

# ── 20. Wallpapers ────────────────────────────────────────────────────────────
log "Wallpapers"
WALLPAPER_SRC="$SCRIPT_DIR/wallpapers"
WALLPAPER_DEST="$HOME/Downloads/Wallpaper"
if [[ -d "$WALLPAPER_SRC" ]]; then
  mkdir -p "$WALLPAPER_DEST"
  WALLPAPER_COUNT=0
  for f in "$WALLPAPER_SRC"/*; do
    [[ -f "$f" ]] || continue
    if [[ -f "$WALLPAPER_DEST/$(basename "$f")" ]]; then
      continue
    fi
    cp "$f" "$WALLPAPER_DEST/"
    WALLPAPER_COUNT=$((WALLPAPER_COUNT + 1))
  done
  if [[ "$WALLPAPER_COUNT" -gt 0 ]]; then
    ok "Copied $WALLPAPER_COUNT wallpaper(s) to $WALLPAPER_DEST."
  else
    ok "Wallpapers already present in $WALLPAPER_DEST."
  fi
else
  warn "No wallpapers directory found at $WALLPAPER_SRC — skipping."
fi

# ── General aliases & env vars ────────────────────────────────────────────────
log "General aliases & env vars"
append_if_missing 'export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"'
append_if_missing 'alias cls="clear"'
append_if_missing 'alias cc="claude"'
append_if_missing 'export EDITOR="nvim"'
append_if_missing 'export VISUAL="nvim"'
ok "'cls', 'cc' aliases and EDITOR/VISUAL env vars set in ~/.zshrc."

# ── Git aliases ───────────────────────────────────────────────────────────────
log "Git aliases"
append_if_missing 'alias gst="git status"'
append_if_missing 'alias gpl="git pull"'
append_if_missing 'alias gl="git log --oneline --graph --decorate"'
append_if_missing 'alias gpf="git push --force-with-lease"'
append_if_missing 'alias gce="git commit --amend --no-edit"'

# Smart gco: checkout existing branch or create + track new one
GCO_FUNC='gco() {
  if git show-ref --verify --quiet "refs/heads/$1"; then
    git checkout "$1"
  elif git show-ref --verify --quiet "refs/remotes/origin/$1"; then
    git checkout --track "origin/$1"
  else
    git checkout -b "$1"
  fi
}'
grep -qxF 'gco() {' "$ZSHRC" 2>/dev/null || echo "$GCO_FUNC" >> "$ZSHRC"
ok "Git aliases added to ~/.zshrc (gst, gpl, gco, gl, gpf, gce)."

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}┌─────────────────────────────────────────────┐${RESET}"
echo -e "${GREEN}${BOLD}│   ✅  Setup complete! Restart your terminal. │${RESET}"
echo -e "${GREEN}${BOLD}└─────────────────────────────────────────────┘${RESET}"
echo ""
echo -e "  Next steps:"
echo -e "  • ${BOLD}Docker${RESET}      — open Docker.app from /Applications to start the daemon"
echo -e "  • ${BOLD}gh auth${RESET}     — run: ${BOLD}gh auth login${RESET}"
echo -e "  • ${BOLD}Rails${RESET}       — create a new app: ${BOLD}rails new myapp${RESET}"
echo -e "  • ${BOLD}nvim${RESET}        — run once to let LazyVim bootstrap all plugins"
echo -e "  • ${BOLD}Python${RESET}      — virtualenvs: ${BOLD}python3 -m venv .venv${RESET}"
echo -e "  • ${BOLD}claude${RESET}      — run in a project dir; authenticate on first launch"
echo -e "  • ${BOLD}opencode${RESET}    — run in a project dir; use /connect to add your LLM key"
echo -e "  • ${BOLD}Wallpapers${RESET}  — pick one from ~/Downloads/Wallpaper in System Settings → Wallpaper"
echo ""

log "Desktop app setup"
warn "Open Raycast, Superwhisper, Arc, Google Chrome, Spotify, Slack, Notion Calendar, Claude, and Codex to complete setup."
warn "Approve macOS permission requests and sign in where required."
# The default macOS Bash can treat an empty array as unset with set -u.
if [[ ${MANUAL_APPS[@]+set} ]]; then
  warn "These items require manual installation:"
  printf '  %s\n' "${MANUAL_APPS[@]}"
fi
