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
# Re-entry Logic to Handle Shell Reloads
###############################################################################
if [ "${SCRIPT_REENTRY:-}" != "true" ]; then
  export SCRIPT_REENTRY="true"
  if [ "$SHELL" != "$(which zsh)" ]; then
    print_step "Changing default shell to zsh..."
    chsh -s "$(which zsh)" || print_warning "Could not change shell automatically."

    print_step "Starting zsh for setup..."
    exec zsh "$0"  # Restart the script with zsh
  fi
fi

###############################################################################
# Helper Functions
###############################################################################
pause_for_user() {
  print_warning "Press any key to continue..."
  read -r
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

      if [ ! -f ~/.zprofile ]; then
        touch ~/.zprofile
      fi

      if ! grep -q "brew shellenv" ~/.zprofile 2>/dev/null; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        print_success "Added Homebrew to ~/.zprofile"
      else
        print_warning "Homebrew is already configured in ~/.zprofile"
      fi

      eval "$(/opt/homebrew/bin/brew shellenv)"
      print_success "Homebrew environment configured for current session."

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

  # Save to disk (not iCloud) by default
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

  # Restart affected applications
  print_step "Restarting Dock and Finder to apply changes..."
  killall Dock &>/dev/null || true
  killall Finder &>/dev/null || true

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

install_rust() {
  print_step "Installing Rust using rustup..."
  if ! command -v rustup &>/dev/null; then
    print_step "Downloading and installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    print_success "Rust installed successfully."
  else
    print_success "Rust is already installed. Updating..."
    rustup update
  fi

  print_step "Setting up default components..."
  rustup default stable
  rustup component add clippy rustfmt
  print_success "Rust default components installed."

  source "$HOME/.cargo/env"
}

install_development_tools() {
  print_step "Installing Development Tools via Homebrew..."
  brew install \
    neovim \
    tmux \
    fzf \
    ripgrep \
    fd \
    eza \
    nerdfetch

  print_success "Development tools installed."
}

install_zsh_plugins() {
  print_step "Installing ZSH plugins..."

  ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
  ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

  if [ ! -d "$ZSH_DIR" ]; then
    print_warning "oh-my-zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
      print_error "Failed to install oh-my-zsh."
      exit 1
    }

    exec zsh "$0"  # Restart script with zsh
  fi

  mkdir -p "$ZSH_CUSTOM_DIR/plugins"

  AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
  if [ ! -d "$AUTOSUGGESTIONS_DIR" ]; then
    print_step "Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR" || {
      print_error "Failed to clone zsh-autosuggestions."
      exit 1
    }
  else
    print_warning "zsh-autosuggestions already installed at $AUTOSUGGESTIONS_DIR"
  fi

  SYNTAX_HIGHLIGHTING_DIR="$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
  if [ ! -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
    print_step "Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_HIGHLIGHTING_DIR" || {
      print_error "Failed to clone zsh-syntax-highlighting."
      exit 1
    }
  else
    print_warning "zsh-syntax-highlighting already installed at $SYNTAX_HIGHLIGHTING_DIR"
  fi
}

configure_zshrc() {
  print_step "Configuring ~/.zshrc..."

  # Backup the original file
  cp ~/.zshrc ~/.zshrc.backup

  # Update the plugins line if it exists
  if grep -q "^plugins=(.*git.*)$" ~/.zshrc; then
    # If plugins line exists and already has git, just add our new plugins
    sed -i '' '/^plugins=(/c\
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' ~/.zshrc
  else
    # If plugins line exists but without git
    if grep -q "^plugins=(" ~/.zshrc; then
      sed -i '' '/^plugins=(/c\
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' ~/.zshrc
    else
      # If no plugins line exists, append it
      echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" >> ~/.zshrc
    fi
  fi

  # Check if ZSH export already exists
  if ! grep -q "export ZSH=\"\$HOME/.oh-my-zsh\"" ~/.zshrc; then
    echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc
  fi

  # Check if theme setting already exists
  if ! grep -q "^ZSH_THEME=" ~/.zshrc; then
    echo 'ZSH_THEME="robbyrussell"' >> ~/.zshrc
  fi

  # Check if source command already exists
  if ! grep -q "source \$ZSH/oh-my-zsh.sh" ~/.zshrc; then
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc
  fi

  print_success "~/.zshrc has been updated."
  print_warning "Backup of original .zshrc saved as ~/.zshrc.backup"
}

install_terminal_font() {
  print_step "Installing Nerd Font for terminal..."
  brew install font-jetbrains-mono-nerd-font

  print_success "JetBrains Mono Nerd Font installed."
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
  brew install libpq
  brew link --force libpq
  echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
}

install_apps() {
  print_step "Installing apps from brew..."

  brew install --cask alt-tab
  brew install --cask wezterm
  brew install --cask mac-mouse-fix
  brew install font-caskaydia-cove-nerd-font
  brew install --cask brave-browser

  print_success "Applications installed."
}

setup_alias() {
  print_step "Setting up aliases..."
  cat << 'EOF' >> ~/.zshrc

# Custom aliases
alias ls="eza --icons=always"
alias ll="eza -al --icons"
alias lt="eza -T --icons"
EOF

  print_success "Aliases configured."
}

###############################################################################
# Main Script Execution
###############################################################################
print_step "Starting macOS setup script..."

install_xcode_command_line_tools
install_homebrew
configure_macos_defaults
configure_git
install_rust
install_development_tools
# install_zsh_plugins
# configure_zshrc
install_terminal_font
install_apps
install_aptos_dev_setup
setup_alias

print_success "Setup complete! Some changes may require a logout or restart to take full effect."
