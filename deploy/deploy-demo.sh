cd dotfiles/Brew
if [ "$WORK" == 1 ];
  then cd work
  brew bundle
fi
if [ "$HOME" == 1 ];
  then cd home
  brew bundle
fi
