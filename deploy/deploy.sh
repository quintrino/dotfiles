# sudo curl -fsSL  https://raw.githubusercontent.com/quintrino/dotfiles/master/deploy/deploy.sh | WORK=1 bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
git clone https://github.com/quintrino/dotfiles.git
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

