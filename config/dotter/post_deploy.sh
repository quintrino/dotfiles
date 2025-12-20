echo "\033[1;31mRunning Post Deploy Hooks\033[0m"
echo "Generating symlinks"
echo "Symlinking apps/vlc/vlcrc"
ln -sf ~/.dotfiles/apps/vlc/vlcrc ~/Library/Preferences/org.videolan.vlc/vlcrc
echo "Symlinking apps/vs-code/settings.vsrc"
ln -sf ~/.dotfiles/apps/vs-code/settings.vsrc ~/Library/Application\ Support/Code/User/settings.json
echo "Symlinking apps/vs-code/settings.vsrc"
ln -sf ~/.dotfiles/apps/vs-code/keys.vsrc ~/Library/Application\ Support/Code/User/keybindings.json
if [ -d $HOME/Proton ]; then
      echo "/Proton/ detected"
      echo "Generating symlinks"
      echo "Symlinking Devices/Mac/private.yml"
      ln -sf ~/Proton/Sync/Devices/Mac/private.yml $XDG_CONFIG_HOME/espanso/match/private.yml
else
  echo "Proton Drive not found"
fi
merge_upload $ESPANSO_MATCH/base.yml $ESPANSO_MATCH/private.yml espanso.yml $ESPANSO_FILE_ID
