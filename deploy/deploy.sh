# sudo curl -fsSL  https://raw.githubusercontent.com/quintrino/dotfiles/master/deploy/deploy.sh | WORK=1 bash
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

git clone https://github.com/quintrino/dotfiles.git .dotfiles

source $HOME/.dotfiles/deploy_functions.sh

install_homebrew
install_zplugin
install_brew_bundle
set_edit
install_zsh_defaults
install_fresh
install_apple_defaults
set_iterm_defaults
