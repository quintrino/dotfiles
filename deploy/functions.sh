#!/bin/zsh

# shellcheck disable=SC1090
source "$HOME/.dotfiles/shell/environment"

function install_homebrew() {
  printf "\033[1;31mInstalling Homebrew \033[0m\n"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}


function install_zinit() {
  printf "\033[1;31mInstalling Zinit \033[0m\n"
  ZINIT_HOME=$XDG_CONFIG_HOME/zinit sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
}

function install_fisher() {
  echo 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher' | fish
  echo 'fisher update' | fish | rg -v "has unsynchronized changes"
}

function install_brew_bundle() {
  printf "\033[1;31mBrew Bundle Install \033[0m\n"
  cd "$HOME/.dotfiles/brew" || exit
  brew bundle
  if [ "$WORK" == 1 ];
    then cd work || exit
    brew bundle
  fi
  if [ "$HOME" == 1 ];
    then cd home || exit
    brew bundle
  fi
  cd || exit
}

function configure_filetypes() {
  printf "\033[1;31mConfigure Filetype default applications \033[0m\n"
  duti ~/.dotfiles/deploy/duti.config
}

function install_config_folders() {
  printf "\033[1;31mInstalling Config Folders \033[0m\n"
  mkdir -p ~/Library/Application\ Support/Code/User/
  mkdir -p "$XDG_CACHE_HOME/less"
  mkdir -p "$XDG_DATA_HOME/zsh"
  mkdir -p "$HOME/Code/personal"
  mkdir -p "$HOME/Code/personal/exercism"
  mkdir -p "$XDG_DATA_HOME/bash"
  mkdir -p "$XDG_DATA_HOME/gnupg"
  mkdir -p "$HOME/Library/ApplicationSupport/MTMR"
  mkdir -p "$XDG_CONFIG_HOME/karabiner"
  mkdir -p "$XDG_CONFIG_HOME/zinit/bin"
  mkdir -p "$XDG_CONFIG_HOME/hammerspoon"
  mkdir -p "$XDG_CONFIG_HOME/fish"
  mkdir -p "$XDG_CONFIG_HOME/tmux"
  mkdir -p "$XDG_CONFIG_HOME/tmuxinator"
  mkdir -p "$XDG_CONFIG_HOME/npm"
  mkdir -p "$XDG_CONFIG_HOME/zsh"
}

function install_zsh_defaults() {
  printf "\033[1;31mSetting Default Shell \033[0m\n"
  [ -f "$HOME/.local/share/zsh/zshrc" ] || echo '#!/bin/zsh' >> "$HOME/.local/share/zsh/zshrc"
  sudo sh -c 'echo /usr/local/bin/zsh >> /etc/shells' # Set brew zsh as acceptable shell choice
  chsh -s /usr/local/bin/zsh # Set shell to brew zsh
  chmod go-w '/usr/local/share' # To allow Zsh-completions to work without issues
}

function install_fresh() {
  printf "\033[1;31mInstall Fresh \033[0m\n"
  rm "$HOME/.zshrc"
  mkdir -p "$XDG_CONFIG_HOME/fresh/source/freshshell"

  if [ -d "$XDG_CONFIG_HOME/fresh/source/freshshell/fresh" ]; then
    cd "$XDG_CONFIG_HOME/fresh/source/freshshell/fresh" || exit
    git pull --rebase
    cd "$OLDPWD" || exit
  else
    git clone https://github.com/freshshell/fresh "$XDG_CONFIG_HOME/fresh/source/freshshell/fresh"
  fi

  FRESH_LOCAL="${FRESH_LOCAL:-$HOME/.dotfiles}"
  if [ -n "$FRESH_LOCAL_SOURCE" ] && ! [ -d "$FRESH_LOCAL" ]; then
    if ! [[ "$FRESH_LOCAL_SOURCE" == */* || "$FRESH_LOCAL_SOURCE" == *:* ]]; then
      echo 'FRESH_LOCAL_SOURCE must be either in user/repo format or a full Git URL.' >&2
      exit 1
    fi

    if echo "$FRESH_LOCAL_SOURCE" | grep -q :; then
      git clone "$FRESH_LOCAL_SOURCE" "$FRESH_LOCAL"
    else
      git clone "https://github.com/$FRESH_LOCAL_SOURCE.git" "$FRESH_LOCAL"
      git --git-dir="$FRESH_LOCAL/.git" remote set-url --push origin "git@github.com:$FRESH_LOCAL_SOURCE.git"
    fi
  fi

  if ! [ -e "$FRESH_RCFILE" ]; then
    if [ -r "$FRESH_LOCAL/freshrc" ]; then
      ln -s "$FRESH_LOCAL/freshrc" "$FRESH_RCFILE"
    fi
  fi
  "$XDG_CONFIG_HOME/fresh/source/freshshell/fresh/bin/fresh"
}

function install_asdf_defaults() {
  printf "\033[1;31mInstalling ASDF Defaults \033[0m\n"
  while read -r lang; do
    asdf plugin-add $lang
    latest="$(asdf latest $lang)"
    asdf install $lang $latest
    asdf global $lang $latest
    asdf reshim $lang
  done <"$HOME/.dotfiles/config/asdf/static"
}

function install_apple_defaults() {
  printf "\033[1;31mInstalling Apple Defaults \033[0m\n"
  # Disable the sound effects on boot
  sudo nvram SystemAudioVolume=" "

  # Apple defaults

  # Disable the “Are you sure you want to open this application?” dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  # Reveal IP address, hostname, OS version, etc. when clicking the clock
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

  # Restart automatically if the computer freezes
  sudo systemsetup -setrestartfreeze on

  # Disable smart quotes as they’re annoying when typing code
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

  # Disable smart dashes as they’re annoying when typing code
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

  # Check for software updates daily, not just once per week
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

  # Set menubar to show percentage
  defaults write com.apple.menuextra.battery ShowPercent YES

  # Trackpad: enable tap to click for this user and for the login screen
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  # Enable key repeat globally
  defaults write -g ApplePressAndHoldEnabled -bool false

  # Set a blazingly fast keyboard repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 10

  # # Use scroll gesture with the Ctrl (^) modifier key to zoom
  # defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
  # defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
  # # Follow the keyboard focus while zoomed in
  # defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

  # Require password immediately after sleep or screen saver begins
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  # Show the ~/Library folder
  chflags nohidden ~/Library

  # Disable Dashboard
  defaults write com.apple.dashboard mcx-disabled -bool true

  # Don’t show Dashboard as a Space
  defaults write com.apple.dock dashboard-in-overlay -bool true

  # Wipe all (default) app icons from the Dock
  defaults write com.apple.dock persistent-apps -array

  # Don’t automatically rearrange Spaces based on most recent use
  defaults write com.apple.dock mru-spaces -bool false

  # Set Dock to the Left
  defaults write com.apple.dock orientation -string left

  # Automatically hide and show the Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0
  defaults write com.apple.dock static-only -bool true
  killall Dock

  # Set Clock to 24 hour time
  defaults write com.apple.menuextra.clock "DateFormat" 'EEE d MMM HH:mm'

  # Allow installing user scripts via GitHub Gist or Userscripts.org
  # defaults write com.google.Chrome ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"
  # defaults write com.google.Chrome.canary ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"

  # Set Hammerspoon to use XDG config location
  defaults write org.hammerspoon.Hammerspoon MJConfigFile "$XDG_CONFIG_HOME/hammerspoon/init.lua"

  # Reset SystemUIServer
  killall -KILL SystemUIServer
}

function set_iterm_defaults() {
  printf "\033[1;31mSetting iTerm Defaults \033[0m\n"
  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.dotfiles/apps/iTerm"
  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
}

function set_dash_defaults() {
  printf "\033[1;31mSetting Dash Defaults \033[0m\n"
  # Specify the preferences directory
  defaults write com.kapeli.dashdoc shouldSyncBookmarks -bool true
  defaults write com.kapeli.dashdoc shouldSyncDocsets -bool true
  defaults write com.kapeli.dashdoc shouldSyncGeneral -bool true
  defaults write com.kapeli.dashdoc shouldSyncView -bool true
  defaults write com.kapeli.dashdoc syncFolderPath -string "$HOME/.dotfiles/apps/Dash"
}

function remind_install_steps() {
  while read -r line; do
    echo "$line"
  done <"$HOME/.dotfiles/deploy/post_deploy_steps"
}

function set_computer_name() {
  sudo scutil --set HostName "$1"
  sudo scutil --set LocalHostName "$1"
  sudo scutil --set ComputerName "$1"
}

function install_personal_projects() {
  mkdir -p $HOME/Code/Personal
  cd $HOME/Code/Personal || exit
  while read -r line; do
    git clone "git@github.com:quintrino/$line.git"
  done <~/.dotfiles/deploy/personal_projects
}

function deploy_from_step() {

  set -e

  local stepNumber=$1

  if [ $stepNumber -eq 1 ]
  then
    install_config_folders
  fi

  if [ $stepNumber -le 2 ]
  then
    install_homebrew
  fi

  if [ $stepNumber -le 3 ]
  then
    install_zinit
  fi

  if [ $stepNumber -le 4 ]
  then
    (install_brew_bundle || true)
  fi

  if [ $stepNumber -le 5 ]
  then
    install_asdf_defaults
  fi

  if [ $stepNumber -le 6 ]
  then
    install_fresh
  fi

  if [ $stepNumber -le 7 ]
  then
    install_fisher
  fi

  if [ $stepNumber -le 8 ]
  then
    install_apple_defaults
  fi

  if [ $stepNumber -le 9 ]
  then
    install_zsh_defaults
  fi

  if [ $stepNumber -le 10 ]
  then
    set_iterm_defaults
  fi

  if [ $stepNumber -le 11 ]
  then
    configure_filetypes
  fi

  if [ $stepNumber -le 12 ]
  then
    install_personal_projects
  fi

  if [ $stepNumber -le 13 ]
  then
    remind_install_steps
  fi

}
