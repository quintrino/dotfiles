# sudo curl -fsSL  https://raw.githubusercontent.com/quintrino/dotfiles/master/deploy/deploy.sh | WORK=1 bash
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
brew install ruby-install
ruby-install --latest ruby
source /usr/local/share/chruby/chruby.sh
chruby 2.5.1
cd dotfiles/ruby
gem install bundler
bundle
