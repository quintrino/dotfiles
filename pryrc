#!/usr/bin/env ruby

Pry.commands.block_command(/!(\d+)/, 'Replay a line of history') do |line|
  run "history --replay #{line}"
end

Pry.config.commands.alias_command 'h', 'hist -T 20', desc: 'Last 20 commands'

Pry::Commands.block_command 'e', 'exit pry' do
  run exit
end

Pry.commands.alias_command 'l', 'whereami'
Pry.commands.alias_command 'bt', 'pry-backtrace'
Pry.commands.alias_command 'sm_pry', 'show-method'
Pry.commands.alias_command 'ds_pry', 'disable-pry'
Pry.commands.alias_command 'rl_pry', 'reload-code' # Reloads the code

Pry.editor = 'subl'

Pry.config.ls.separator = "\n" # new lines between methods
Pry.config.ls.heading_color = :magenta
Pry.config.ls.public_method_color = :green
Pry.config.ls.protected_method_color = :yellow
Pry.config.ls.private_method_color = :bright_black

Pry::CommandSet.new do
  command 'copy', 'Copy argument to the clip-board' do |str|
    IO.popen('pbcopy', 'w') { |f| f << str.to_s }
  end
end

def gemdir
  @gemdir ||= "#{`gem env gemdir`.chomp}/gems"
end

def load_non_bundled_plugins(plugin)
  gem_version = Dir.entries(gemdir).detect { |s| s[/^#{plugin}\-[0-9]/] }
  $LOAD_PATH << "#{gemdir}/#{gem_version}/lib"
  require plugin
rescue LoadError
  puts "no #{plugin} :("
end

[
  'awesome_print',
  'debug_inspector',
  'binding_of_caller',
  'pry-stack_explorer',
  'rb-readline'
].each do |plugin|
  load_non_bundled_plugins(plugin)
end

if defined?(AwesomePrint)
  AwesomePrint.defaults = {
    indent: -1, # left aligned
    sort_keys: true, # sort hash keys
    # more customization
  }
  Pry.config.print = proc do |output, value|
    Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output)
  end
end

if defined?(PryByebug)
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end

require 'rbreadline'
if defined?(RbReadline)
  def RbReadline.rl_reverse_search_history(_sign, _key)
    rl_insert_text `cat ~/.pry_history | fzf --tac --height 16 |  tr '\n' ' '`
  end
end
