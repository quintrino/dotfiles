Pry.commands.block_command(/!(\d+)/, 'Replay a line of history', :listing => '!hist') do |line|
  run "history --replay #{line}"
end

Pry.config.commands.alias_command 'h', 'hist -T 20', desc: 'Last 20 commands'

Pry::Commands.block_command "e", "exit pry" do
  run exit
end

if defined?(PryByebug)
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end

Pry.commands.alias_command 'l', 'whereami'
Pry.commands.alias_command 'bt', 'pry-backtrace'


Pry.editor = 'subl'

Pry.config.ls.separator = "\n" # new lines between methods
Pry.config.ls.heading_color = :magenta
Pry.config.ls.public_method_color = :green
Pry.config.ls.protected_method_color = :yellow
Pry.config.ls.private_method_color = :bright_black


default_command_set = Pry::CommandSet.new do
  command "copy", "Copy argument to the clip-board" do |str|
     IO.popen('pbcopy', 'w') { |f| f << str.to_s }
  end
end

begin
  require 'awesome_print'
  AwesomePrint.defaults = {
    indent: -2, # left aligned
    sort_keys: true, # sort hash keys
    # more customization
  }
  Pry.config.print = proc { |output, value| Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output) }
rescue LoadError => err
  puts "no awesome_print :("
end
