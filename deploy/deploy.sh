#!/bin/zsh

# curl -fsSL https://raw.githubusercontent.com/quintrino/dotfiles/master/deploy/deploy.sh | zsh

set -e

if [[ $(xcode-select -p 1>/dev/null;echo $?) -eq 0 ]]; then
  echo "XCode CLI installed"
else
  xcode-select --install
fi

if [ -d "$HOME/.dotfiles" ]; then
    cd "$HOME/.dotfiles"
    git pull --rebase
    cd "$OLDPWD"
  else
    git clone https://github.com/quintrino/dotfiles.git .dotfiles
  fi

# shellcheck disable=SC1090
source "$HOME/.dotfiles/deploy/functions.sh"

deploy_from_step 1 |& tee -a "$HOME/.dotfiles/deploy/log"
