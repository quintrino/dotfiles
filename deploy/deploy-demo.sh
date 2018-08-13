source /usr/local/share/chruby/chruby.sh
chruby 2.5.1
cd dotfiles/ruby
gem install bundler
bundle
echo 'EOF'
