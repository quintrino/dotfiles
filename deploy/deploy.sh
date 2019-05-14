# sudo curl -fsSL  https://raw.githubusercontent.com/quintrino/dotfiles/master/deploy/deploy.sh | WORK=1 bash

git clone https://github.com/quintrino/dotfiles.git .dotfiles

source $HOME/.dotfiles/deploy/deploy_functions.sh
source $HOME/.dotfiles/environment

install_config_folders
install_homebrew
install_zplugin
install_brew_bundle
set_edit
install_zsh_defaults
install_fresh
install_asdf_defaults
install_apple_defaults
set_iterm_defaults
