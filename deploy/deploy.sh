# sudo curl -fsSL  https://raw.githubusercontent.com/quintrino/dotfiles/master/deploy/deploy.sh | WORK=1 bash

set -e

if [[ $(xcode-select -p 1>/dev/null;echo $?) -eq 0 ]]; then
  echo "XCode CLI installed"
else
  xcode-select --install
fi

if [ -d $HOME/.dotfiles ]; then
    cd $HOME/.dotfiles
    git pull --rebase
    cd "$OLDPWD"
  else
    git clone https://github.com/quintrino/dotfiles.git .dotfiles
  fi

source $HOME/.dotfiles/deploy/deploy_functions.sh
source $HOME/.dotfiles/environment

install_config_folders
install_homebrew
install_zplugin
install_brew_bundle
set_edit
install_fresh
install_asdf_defaults
install_apple_defaults
set_iterm_defaults
install_zsh_defaults
remind_install_steps
