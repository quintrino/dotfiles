brew install ruby-install
ruby-install --latest ruby
chruby 2.5.1
cd dotfiles/ruby
gem install bundler
bundle
echo 'EOF'
