echo "\033[1;31mRunning Post Deploy Hooks\033[0m"
echo "Generating symlinks"
echo "Symlinking apps/vlc/vlcrc"
ln -sf ~/.dotfiles/apps/vlc/vlcrc ~/Library/Preferences/org.videolan.vlc/vlcrc
echo "Symlinking config/karabiner/"
KARABINER_DIRECTORY="$XDG_CONFIG_HOME/karabiner"
[ -d "$KARABINER_DIRECTORY" ] && [ ! -L "$KARABINER_DIRECTORY" ] && rm -rf "$KARABINER_DIRECTORY"
ln -sf ~/.dotfiles/config/karabiner/ $XDG_CONFIG_HOME/
echo "Generating Karabiner config file"
ruby ~/.dotfiles/config/karabiner/generate_karabiner.rb
echo "Symlinking apps/vs-code/settings.vsrc"
ln -sf ~/.dotfiles/apps/vs-code/settings.vsrc ~/Library/Application\ Support/Code/User/settings.json
echo "Symlinking apps/vs-code/settings.vsrc"
ln -sf ~/.dotfiles/apps/vs-code/keys.vsrc ~/Library/Application\ Support/Code/User/keybindings.json
clang -F /System/Library/PrivateFrameworks -framework login -o $HOME/Library/LaunchAgents/Scripts/bin/locknow $HOME/.dotfiles/shell/tasks/locknow.c
if [ -d $HOME/Proton ]; then
      echo "/Proton/ detected"
      echo "Generating symlinks"
      echo "Symlinking Devices/Mac/private.yml"
      ln -sf ~/Proton/Sync/Devices/Mac/private.yml $XDG_CONFIG_HOME/espanso/match/private.yml
else
  echo "Proton Drive not found"
fi
TIMEOUT_FOLDER="$HOME/Library/Application Scripts/com.dejal.timeout/Break Actions"
if [ -d "$TIMEOUT_FOLDER" ]; then
  echo "Exporting Timeout scripts"
  for script in ~/.dotfiles/apps/timeout/*.applescript; do
    name=$(basename "$script" .applescript)
    osacompile -o "$TIMEOUT_FOLDER/$name.scpt" "$script"
  done
fi


if [ -d "$ESPANSO_MATCH" ] && [ -z "$ESPANSO_OFF" ]; then
  echo "Espanso Match files located"
  $HOME/.dotfiles/shell/utilities/merge_upload $ESPANSO_MATCH/base.yml $ESPANSO_MATCH/private.yml espanso.yml $ESPANSO_FILE_ID
fi

