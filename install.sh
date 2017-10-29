#!/bin/bash

set -e

yellow() {
  tput setaf 3
  echo "$*"
  tput sgr0
}

info(){
  echo
  yellow "$@"
}

quietly_brew_bundle(){
  brew bundle --file="$1" | \
    grep -vE '^(Using |Homebrew Bundle complete)' || \
    true
}

is_osx(){
  [ "$(uname -s)" = Darwin ]
}

is_linux(){
  [ "$(uname -s)" = Linux ]
}

if is_osx; then
  info "Installing Homebrew if not already installed..."
  if ! command -v brew > /dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  info "Installing Homebrew packages..."
  brew tap homebrew/bundle
  for brewfile in Brewfile Brewfile.casks */Brewfile; do
    quietly_brew_bundle "$brewfile"
  done

  # moreutils contains a `parallel` command, and Homebrew unlinks it when it
  # sees the conflict. Relink them both.
  brew link --overwrite parallel
  brew link --overwrite moreutils
  # --overwrite: overwrite any Qt4 files that might be there
  # --force: required because Qt is keg-only
  brew link --overwrite --force qt@5.5 &>/dev/null

  info "Checking for command-line tools..."
  if ! command -v xcodebuild > /dev/null; then
    xcode-select --install
  fi
fi

if ! echo "$SHELL" | grep -Fq zsh; then
  info "Your shell is not Zsh. Changing it to Zsh..."
  chsh -s /bin/zsh
fi

info "Linking dotfiles into ~..."
# Before `rcup` runs, there is no ~/.rcrc, so we must tell `rcup` where to look.
# We need the rcrc because it tells `rcup` to ignore thousands of useless Vim
# backup files that slow it down significantly.
RCRC=rcrc rcup -d .

info "Installing zsh-syntax-highlighting..."
if [ ! -d ~/.zsh-plugins/zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh-plugins/zsh-syntax-highlighting
fi

info "Installing Vim packages..."
vim +PlugInstall +qa

if is_osx; then
  info "If you like what you see in system/osx-settings, run ./system/osx-settings"
  info "If you're using Terminal.app, check out the terminal-themes directory"
fi

info "Installing fonts..."
if is_osx; then
  if ! system_profiler SPFontsDataType | grep -Eq 'Full Name: Iosevka$'; then
    open fonts/iosevka*
  fi

  if ! system_profiler SPFontsDataType | grep -q 'Inconsolata-Regular'; then
    open fonts/Inconsolata*
  fi
fi

info "Running all setup scripts..."
for setup in tag-*/setup; do
  dir=$(basename "$(dirname "$setup")")
  info "Running setup for ${dir#tag-}..."
  . "$setup"
done

# asdf
if ! asdf plugin-list | grep -Fq ruby; then
  asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
fi

if ! asdf plugin-list | grep -Fq nodejs; then
  asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
fi

# Migrate from rbenv -> asdf
if [ -d ~/.rbenv/versions ]; then
  mkdir -p /usr/local/opt/asdf/installs/ruby
  mv ~/.rbenv/versions/* /usr/local/opt/asdf/installs/ruby/
fi
