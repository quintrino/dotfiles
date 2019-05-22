
function install_homebrew() {
  echo -e "\033[1;31mInstalling Homebrew \033[0m"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}


function install_zplugin() {
  echo -e "\033[1;31mInstalling Zplugin \033[0m"
  ZPLG_HOME=$XDG_CONFIG_HOME/zplugin sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"
}

function install_brew_bundle() {
  echo -e "\033[1;31mBrew Bundle Install \033[0m"
  cd $HOME/.dotfiles/brew
  brew bundle
  if [ "$WORK" == 1 ];
    then cd work
    brew bundle
  fi
  if [ "$HOME" == 1 ];
    then cd home
    brew bundle
  fi
  cd
}

function install_config_folders() {
  echo -e "\033[1;31mInstalling Config Folders \033[0m"
  mkdir -p ~/Library/Application\ Support/Code/User/
  mkdir -p $XDG_DATA_HOME/z
  touch $XDG_DATA_HOME/z/z
  mkdir -p $XDG_DATA_HOME/zsh
  mkdir -p $XDG_CONFIG_HOME/karabiner
  mkdir -p $XDG_CONFIG_HOME/zplugin/bin
}


function set_edit() {
  echo -e "\033[1;31mSetting Editor \033[0m"
  ln -sv /usr/local/bin/code /usr/local/bin/edit
}

function install_zsh_defaults() {
  echo -e "\033[1;31mSetting Default Shell \033[0m"
  [ -f $HOME/.local/share/zsh/zshrc ] || echo '#!/bin/zsh' >> $HOME/.local/share/zsh/zshrc
  echo /usr/local/bin/zsh >> /etc/shells # Set brew zsh as acceptable shell choice
  chsh -s /usr/local/bin/zsh # Set shell to brew zsh
  chmod go-w '/usr/local/share' # To allow Zsh-completions to work without issues
}

function install_fresh() {
  echo -e "\033[1;31mInstall Fresh \033[0m"
  rm $HOME/.zshrc
  mkdir -p $XDG_CONFIG_HOME/fresh/source/freshshell

  if [ -d $XDG_CONFIG_HOME/fresh/source/freshshell/fresh ]; then
    cd $XDG_CONFIG_HOME/fresh/source/freshshell/fresh
    git pull --rebase
    cd "$OLDPWD"
  else
    git clone https://github.com/freshshell/fresh $XDG_CONFIG_HOME/fresh/source/freshshell/fresh
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

  if ! [ -e $FRESH_RCFILE ]; then
    if [ -r "$FRESH_LOCAL/freshrc" ]; then
      ln -s "$FRESH_LOCAL/freshrc" $FRESH_RCFILE
    fi
  fi
  $XDG_CONFIG_HOME/fresh/source/freshshell/fresh/bin/fresh
}

function install_asdf_defaults() {
  echo -e "\033[1;31mInstalling ASDF Defaults \033[0m"
  while read line; do
    asdf plugin-add "$(echo $line | cut -f 1 -d " " )"
    case "$(echo $line | cut -f 1 -d " " )" in
      "nodejs") bash $ASDF_DATA_DIR/plugins/nodejs/bin/import-release-team-keyring
    esac
    asdf install "$(echo $line | cut -f 1 -d " " )" "$(echo $line | cut -f 2 -d " " )"
    asdf global "$(echo $line | cut -f 1 -d " " )" "$(echo $line | cut -f 2 -d " " )"
  done <$HOME/.dotfiles/tool-versions
}

function install_apple_defaults() {
  echo -e "\033[1;31mInstalling Apple Defaults \033[0m"
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

  # Use scroll gesture with the Ctrl (^) modifier key to zoom
  defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
  defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
  # Follow the keyboard focus while zoomed in
  defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

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
  defaults write com.apple.menuextra.clock "DateFormat" 'EEE HH:mm'

  # Allow installing user scripts via GitHub Gist or Userscripts.org
  # defaults write com.google.Chrome ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"
  # defaults write com.google.Chrome.canary ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"

  # Reset SystemUIServer
  killall -KILL SystemUIServer
}

function set_iterm_defaults() {
  echo -e "\033[1;31mSetting iTerm Defaults \033[0m"
  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.dotfiles/iTerm"
  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
}

function remind_install_steps() {
  cat <<-MESSAGE

#Completed before Google Drive Sync and 1Password Sync
Sign into Google Drive, Google Chrome and 1Password
Sign into Apple iCloud account
Set computer name by running set_computer_name COMPUTER_NAME
Set Bettertouchtool to start on login
Enable Karabiner in security and privacy settings
Set Bluetooth to display icon in Menu Bar
Enable Security > Accessibility for Alfred, Bettertouchtool and Bartender
Set Spotlight to control command space in Keyboard > Shortcuts

#Completed after 1Password Sync
Set Bettertouchtool to sync from Dropbox
Enable licence for Bettertouchtool, Alfred and Bartender
Sign into Teamviewer, Anki and Freedom
Add ssh key for Github

#Completed after Google Chrome Sync
Copy 1Password.json from Google Chrome to Google Chrome Canary
Set Chrome uBlock Origin to point to github filter

#Completed after Google Drive Sync
Set Dash and Alfred to Sync from Google Drive
Set Google Drive to ignore warnings for removing shared items
Set Alfred to command space
Set Alfred appearance to stretch

MESSAGE
}

function set_computer_name() {
  sudo scutil --set HostName $1
  sudo scutil --set LocalHostName $1
  sudo scutil --set ComputerName $1
}
