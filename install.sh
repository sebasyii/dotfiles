#!/usr/bin/env bash

###############################################################################
# macOS Setup Script
#
# This script will:
#   1. Check and install Xcode Command Line Tools.
#   2. Check and install Homebrew.
#   3. Configure macOS system defaults.
#   4. Install development tools (neovim, tmux, etc.).
#   5. Configure ZSH (oh-my-zsh plugins, Nerd fonts, etc.).
#
# Usage:
#   1. Make it executable:  chmod +x macos_setup.sh
#   2. Run it:              ./macos_setup.sh
#
###############################################################################

set -Eeuo pipefail  # safer scripting: exit on error, unset variables, or pipefail

###############################################################################
# Color Variables and Print Functions
###############################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step()    { echo -e "${BLUE}==>${NC} $*"; }
print_success() { echo -e "${GREEN}✓${NC} $*"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
print_error()   { echo -e "${RED}✗${NC} $*"; }

###############################################################################
# Helper Functions
###############################################################################
pause_for_user() {
  print_warning "Press any key to continue..."
  read -n 1 -s
}

install_xcode_command_line_tools() {
  print_step "Checking for Xcode Command Line Tools..."
  if xcode-select -p &>/dev/null; then
    print_success "Xcode Command Line Tools already installed."
  else
    print_warning "Xcode Command Line Tools not found. Installing..."
    xcode-select --install

    print_warning "Complete the installer prompt, then:"
    pause_for_user

    if xcode-select -p &>/dev/null; then
      print_success "Xcode Command Line Tools installed."
    else
      print_error "Xcode Command Line Tools installation failed."
      exit 1
    fi
  fi
}

install_homebrew() {
  print_step "Checking for Homebrew installation..."
  if ! command -v brew &>/dev/null; then
    print_warning "Homebrew not found. Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      print_success "Homebrew installation successful."

      print_step "Configuring Homebrew environment..."
      # Avoid duplicates in .zprofile
      if ! grep -q "brew shellenv" ~/.zprofile 2>/dev/null; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        print_success "Added Homebrew to ~/.zprofile"
      else
        print_warning "Homebrew is already configured in ~/.zprofile"
      fi

      eval "$(/opt/homebrew/bin/brew shellenv)"
      print_success "Homebrew environment configured for current session."

      # Check for issues
      if brew doctor; then
        print_success "Homebrew is ready to use!"
      else
        print_warning "Homebrew installed, but 'brew doctor' reported issues."
      fi
    else
      print_error "Homebrew installation failed."
      exit 1
    fi
  else
    print_success "Homebrew is already installed!"
    print_success "Location: $(which brew)"
    print_success "Version:  $(brew --version)"
  fi
}

configure_macos_defaults() {
  print_step "Configuring macOS defaults..."

  # Faster keyboard repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Disable press-and-hold for keys in favor of key repeat
  # If you actually want to "disable" press-and-hold, set to false.
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Show battery percentage in menu bar
  defaults write com.apple.menuextra.battery ShowPercent -string "YES"

  # Dock configuration
  print_step "Configuring Dock..."
  defaults write com.apple.dock persistent-apps -array
  defaults write com.apple.dock persistent-others -array
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock mru-spaces -bool false
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-time-modifier -float 0.5
  defaults write com.apple.dock autohide-delay -float 0.2
  defaults write com.apple.dock minimize-to-application -bool true
  defaults write com.apple.dock tilesize -int 36
  defaults write com.apple.dock mineffect -string "scale"

  # Finder settings
  print_step "Configuring Finder..."
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

  # Safari settings
  print_step "Configuring Safari..."
  defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
  # Save to disk (not iCloud) by default
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

  # Restart affected applications
  print_step "Restarting Dock and Finder to apply changes..."
  killall Dock &>/dev/null || true
  killall Finder &>/dev/null || true
  # Safari only needs a killall if open and we changed certain settings
  # killall Safari &>/dev/null || true

  print_success "macOS system defaults configured."
}

configure_git() {
  print_step "Configuring global Git settings..."
  git config --global user.name "Sebastian Yii"
  git config --global user.email "sebas.yxh@gmail.com"
  git config --global init.defaultBranch main
  git config --global core.editor "nvim"

  print_success "Git configuration updated."
}

install_development_tools() {
  print_step "Installing Development Tools via Homebrew..."
  brew install \
    neovim \
    tmux \
    fzf \
    ripgrep \
    fd \
    exa 

  print_success "Development tools installed."
}

install_zsh_plugins() {
  print_step "Installing ZSH plugins..."

  # Optionally check if oh-my-zsh is installed
  if [ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]; then
    print_warning "oh-my-zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # autosuggestions
  if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  else
    print_warning "zsh-autosuggestions already installed."
  fi

  # syntax highlighting
  if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  else
    print_warning "zsh-syntax-highlighting already installed."
  fi
}

configure_zshrc() {
  print_step "Configuring ~/.zshrc..."
  cat << 'EOF' > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh
EOF

  print_success "~/.zshrc has been updated."
}

install_terminal_font() {
  print_step "Installing Nerd Font for terminal..."
  brew tap homebrew/cask-fonts
  brew install --cask font-jetbrains-mono-nerd-font

  print_success "JetBrains Mono Nerd Font installed."
}

install_rust() {
  print_step "Installing Rust using rustup..."
  if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -- -y
    print_success "Rust installed successfully."
  else
    print_success "Rust is already installed. Updating..."
    rustup update
  fi

  print_step "Setting up default component"
  rustup default stable
  rustup component add clippy rustfmt
  print_success "Rust default components installed"

  source ~/.cargo/env
}

install_aptos_dev_setup() {
  print_step "Installing Aptos specified libraries"
  if ! command -v aptos &>/dev/null; then
    print_step "Installing Aptos CLI using brew..."
    brew install aptos
  else
    print_warning "Aptos CLI already installed. Updating..."
    brew update
    brew install aptos
  fi

  print_step "Installing libraries for building aptos-core..."
  brew install cmake
}

## Install nvm, install pyenv


install_nvm() {
  print_step "Installing nvm..."
  if [ ! -d "$HOME/.nvm" ]; then
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
   print_success "nvm installed successfully."

    if ! grep -q "NVM_DIR" ~/.zshrc; then
      echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "$HOME/.nvm" || printf %s "$XDG_CONFIG_HOME/nvm")"' >> ~/.zshrc
      echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
      print_success "Added nvm to ~/.zshrc"

      source ~/.zshrc
    else
      print_warning "nvm is already configured in ~/.zshrc"
    fi
  else
    print_warning "nvm is already installed."
  fi
}

###############################################################################
# Main Script Execution
###############################################################################
print_step "Starting macOS setup script..."

install_xcode_command_line_tools
install_homebrew

configure_macos_defaults
configure_git

install_development_tools
install_zsh_plugins
configure_zshrc
install_terminal_font

install_rust
install_aptos_dev_setup
install_nvm

print_success "Setup complete! Some changes may require a logout or restart to take full effect."
