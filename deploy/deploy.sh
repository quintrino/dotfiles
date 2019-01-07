# sudo curl -fsSL  https://raw.githubusercontent.com/quintrino/dotfiles/master/deploy/deploy.sh | WORK=1 bash
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
git clone https://github.com/quintrino/dotfiles.git .dotfiles
cd dotfiles/brew
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
echo /etc/shells >> /usr/local/bin/zsh # Set brew zsh as acceptable shell choice
chsh -s /usr/local/bin/zsh # Set shell to brew zsh
chmod go-w '/usr/local/share' # To allow Zsh-completions to work without issues
curl -sL https://get.freshshell.com | bash


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

# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array

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

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Set Clock to 24 hour time
defaults write com.apple.menuextra.clock "DateFormat" 'EEE HH:mm'

# Allow installing user scripts via GitHub Gist or Userscripts.org
# defaults write com.google.Chrome ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"
# defaults write com.google.Chrome.canary ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"

# Reset SystemUIServer
killall -KILL SystemUIServer


# Specify the preferences directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.dotfiles/iTerm"
# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
