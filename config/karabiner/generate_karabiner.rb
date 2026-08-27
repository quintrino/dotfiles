#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

HYPER = %w[right_shift right_control right_command right_option].freeze
HYPER_CMD = (HYPER + %w[left_command]).freeze
SS_FORMAT = '$HOME/Proton/Sync/Devices/Screenshots/Screenshot_'
@ls = 'left_shift'


OUTPUT_PATH = File.expand_path('karabiner.json', __dir__)

def compact_hash(hash)
  hash.reject { |_key, value| value.nil? }
end

def karabiner_config(rules)
  {
    'profiles' => [
      profile('Main', rules)
    ]
  }
end

def profile(name, rules)
  {
    'name' => name,
    'virtual_hid_keyboard' => {
      'keyboard_type_v2' => 'ansi'
    },
    'complex_modifications' => {
      'parameters' => {
        'basic.simultaneous_threshold_milliseconds' => 500,
        'basic.to_delayed_action_delay_milliseconds' => 500
      },
      'rules' => rules
    }
  }
end

def rule(description, manipulators, available_since: nil, conditions: nil)
  compact_hash(
    'description' => description,
    'manipulators' => manipulators,
    'available_since' => available_since,
    'conditions' => conditions
  )
end

def app_specific_rule(description, app, manipulators)
  manipulators_with_app = manipulators.map do |m|
    conditions = m['conditions'] || []
    conditions = Array(conditions) + [app_if([app].flatten)]
    m.merge('conditions' => conditions)
  end

  rule(description, manipulators_with_app)
end

def basic(description = nil, from:, to:, to_if_alone: nil, to_after_key_up: nil, conditions: nil, parameters: nil, log: true)
  compact_hash(
    'description' => description,
    'from' => from,
    'to' => to,
    'to_if_alone' => to_if_alone,
    'to_after_key_up' => logger(description, log),
    'conditions' => conditions,
    'parameters' => parameters,
    'type' => 'basic'
  )
end

def logger(description, log)
  if log
    [{"shell_command": "echo $(date):: '#{description}' >> $HOME/.local/share/karabiner/history"}]
  else
    nil
  end
end

def nested_manipulators(description = nil, manipulators)
  compact_hash('description' => description, 'manipulators' => manipulators)
end

def from_key(key_code, mandatory: nil, optional: nil)
  modifiers = compact_hash('mandatory' => mandatory, 'optional' => optional)
  compact_hash('key_code' => key_code, 'modifiers' => modifiers.empty? ? nil : modifiers)
end

def hyper(key_code)
  modifiers = compact_hash('mandatory' => HYPER)
  compact_hash('key_code' => key_code, 'modifiers' => modifiers )
end

def cmd_hyper(key_code)
  modifiers = compact_hash('mandatory' => HYPER_CMD)
  compact_hash('key_code' => key_code, 'modifiers' => modifiers )
end

def from_simultaneous(keys, optional:, after_key_up:)
  {
    'modifiers' => { 'optional' => optional },
    'simultaneous' => keys.map { |key_code| { 'key_code' => key_code } },
    'simultaneous_options' => {
      'key_down_order' => 'strict',
      'key_up_order' => 'strict_inverse',
      'to_after_key_up' => after_key_up
    }
  }
end

def to_key(key_code, modifiers: nil, hold_down_milliseconds: nil)
  compact_hash(
    'key_code' => key_code,
    'modifiers' => modifiers,
    'hold_down_milliseconds' => hold_down_milliseconds
  )
end

def to_key_then_wait(key_code, times: 1, modifiers: nil, wait_milliseconds: 50)
  Array.new(times) do
    [
      to_key(key_code, modifiers: modifiers),
      to_key('vk_none', hold_down_milliseconds: wait_milliseconds)
    ]
  end.flatten
end

def to_tab_then_wait(times, modifiers: nil, wait_milliseconds: 50)
  to_key_then_wait('tab', times: times, modifiers: modifiers, wait_milliseconds: wait_milliseconds)
end

def to_shell(command)
  { 'shell_command' => command }
end

def open(app)
  { 'shell_command' => "open -a '" + app + ".app'"}
end

def to_button(button)
  { 'pointing_button' => button }
end

def to_mouse(mouse_key)
  { 'mouse_key' => mouse_key }
end

def to_variable(name, value)
  { 'set_variable' => { 'name' => name, 'value' => value } }
end

def to_notification(id, text)
  { 'set_notification_message' => { 'id' => id, 'text' => text } }
end

def to_cursor(position)
  { 'software_function' => { 'set_mouse_cursor_position' => position } }
end

def raw_action(action)
  action
end

def app_if(bundle_identifiers)
  { 'bundle_identifiers' => bundle_identifiers, 'type' => 'frontmost_application_if' }
end

def app_unless(bundle_identifiers)
  { 'bundle_identifiers' => bundle_identifiers, 'type' => 'frontmost_application_unless' }
end

def variable_if(name, value)
  { 'name' => name, 'type' => 'variable_if', 'value' => value }
end

def raw_condition(condition)
  condition
end

def simultaneous_threshold(milliseconds)
  { 'basic.simultaneous_threshold_milliseconds' => milliseconds }
end

MOUSE_KEYS_MODE = 'mouse_keys_mode_v4'
MOUSE_KEYS_SCROLL_MODE = 'mouse_keys_mode_v4_scroll'
MOUSE_KEYS_TITLE = 'Mouse Keys Mode v4'

def mouse_keys_rule
  rule(
    'Mouse Keys Mode v4 (rev 3)',
    [
      *mouse_motion_mappings,
      *mouse_button_mappings,
      *mouse_scroll_mode_mapping,
      *mouse_speed_mappings,
      *mouse_cursor_position_mappings
    ],
    available_since: '13.6.0'
  )
end

def mouse_motion_mappings
  [
    ['j', { 'vertical_wheel' => 32 }, { 'y' => 1536 }],
    ['k', { 'vertical_wheel' => -32 }, { 'y' => -1536 }],
    ['h', { 'horizontal_wheel' => 32 }, { 'x' => -1536 }],
    ['l', { 'horizontal_wheel' => -32 }, { 'x' => 1536 }]
  ].flat_map do |key_code, scroll_action, movement_action|
    [
      mouse_keys_key(key_code, [to_mouse(scroll_action)], conditions: mouse_keys_scroll_conditions),
      mouse_keys_key(key_code, [to_mouse(movement_action)]),
      mouse_keys_chord(key_code, [to_mouse(movement_action)])
    ]
  end
end

def mouse_button_mappings
  [
    ['v', 'button1'],
    ['b', 'button3'],
    ['n', 'button2']
  ].flat_map do |key_code, button|
    action = to_button(button)
    [
      mouse_keys_key(key_code, [action]),
      mouse_keys_chord(key_code, [action])
    ]
  end
end

def mouse_scroll_mode_mapping
  press_scroll = [to_variable(MOUSE_KEYS_SCROLL_MODE, 1)]
  release_scroll = [to_variable(MOUSE_KEYS_SCROLL_MODE, 0)]

  [
    mouse_keys_key('s', press_scroll, to_after_key_up: release_scroll),
    mouse_keys_chord('s', press_scroll, to_after_key_up: release_scroll)
  ]
end

def mouse_speed_mappings
  [
    ['f', { 'speed_multiplier' => 2 }],
    ['g', { 'speed_multiplier' => 0.5 }]
  ].flat_map do |key_code, speed_action|
    action = to_mouse(speed_action)
    [
      mouse_keys_key(key_code, [action]),
      mouse_keys_chord(key_code, [action])
    ]
  end
end

def mouse_cursor_position_mappings
  [
    ['u', { 'x' => '50%', 'y' => '50%' }],
    ['i', { 'x' => '50%', 'y' => '50%', 'screen' => 0 }],
    ['o', { 'x' => '50%', 'y' => '50%', 'screen' => 1 }],
    ['p', { 'x' => '50%', 'y' => '50%', 'screen' => 2 }]
  ].flat_map do |key_code, position|
    action = to_cursor(position)
    [
      mouse_keys_key(key_code, [action]),
      mouse_keys_chord(key_code, [action])
    ]
  end
end

def mouse_keys_key(key_code, actions, conditions: mouse_keys_conditions, to_after_key_up: nil)
  basic(
    'Mouse key: ' + key_code,
    from: from_key(key_code, optional: ['any']),
    to: actions,
    conditions: conditions,
    to_after_key_up: to_after_key_up
  )
end

def mouse_keys_chord(key_code, actions, to_after_key_up: nil)
  basic(
    'Mouse chord: ' + key_code,
    from: from_simultaneous(['q', key_code], optional: ['any'], after_key_up: mouse_keys_cleanup_actions),
    to: mouse_keys_enter_actions + actions,
    parameters: simultaneous_threshold(500),
    to_after_key_up: to_after_key_up
  )
end

def mouse_keys_conditions
  [variable_if(MOUSE_KEYS_MODE, 1)]
end

def mouse_keys_scroll_conditions
  [
    variable_if(MOUSE_KEYS_MODE, 1),
    variable_if(MOUSE_KEYS_SCROLL_MODE, 1)
  ]
end

def mouse_keys_enter_actions
  [
    to_variable(MOUSE_KEYS_MODE, 1),
    to_notification(MOUSE_KEYS_MODE, MOUSE_KEYS_TITLE)
  ]
end

def mouse_keys_cleanup_actions
  [
    to_variable(MOUSE_KEYS_MODE, 0),
    to_variable(MOUSE_KEYS_SCROLL_MODE, 0),
    to_notification(MOUSE_KEYS_MODE, '')
  ]
end

def rules
  [
    app_specific_rule('App-Specific: NaiveChat', 'com.jins.naivechat', [
          basic('NaiveChat: Escape returns to previous app', log: false, from: from_key('caps_lock'), to: [*to_key_then_wait('escape'), to_shell('/usr/local/bin/aerospace workspace-back-and-forth')])
      ]),
    rule('System Modifications - Caps Lock to Hyper Key with Escape on tap', [
          basic('Shift + Caps Lock enables actual Caps Lock', from: from_key('caps_lock', mandatory: ['shift'], optional: ['caps_lock']), to: [to_key('caps_lock')], log: false),
          basic('Caps Lock to Hyper Key (Right Shift + Right Cmd + Right Ctrl + Right Option), Escape on tap', from: from_key('caps_lock', optional: ['any']), to: [to_key('right_shift', modifiers: ['right_command', 'right_control', 'right_option'])], to_if_alone: [to_key('escape')], log: false)
        ]),
    rule('Bose Headphones Activation', [
          basic('Hyper + 3 activates Bose 35 Headphones', from: hyper('3'), to: [to_shell('open alfred://runtrigger/quintrino.bose/35')]),
          basic('Hyper + 4 activates Bose 45 Headphones', from: hyper('4'), to: [to_shell('open alfred://runtrigger/quintrino.bose/45')])
        ]),
    rule('Screenshot Shortcuts - Custom paths to Proton Sync directory', [
          basic('Cmd + Shift + 3: Full screen screenshot to Proton Sync', from: from_key('3', mandatory: ['left_shift', 'left_command']), to: [to_shell("screencapture #{SS_FORMAT}$(date +%Y%m%d-%H%M%S).png")], log: false),
          basic('Cmd + Ctrl + Shift + 3: Full screen screenshot to clipboard', from: from_key('3', mandatory: ['left_shift', 'left_control', 'left_command']), to: [to_shell('screencapture -c')], log: false),
          basic('Cmd + Shift + 4: Selection screenshot to Proton Sync', from: from_key('4', mandatory: ['left_shift', 'left_command']), to: [to_shell("screencapture -s #{SS_FORMAT}$(date +%Y%m%d-%H%M%S).png")], log: false),
          basic('Cmd + Ctrl + Shift + 4: Selection screenshot to clipboard', from: from_key('4', mandatory: ['left_shift', 'left_control', 'left_command']), to: [to_shell('screencapture -cs')], log: false)
        ]),
    rule('Hyper Key - System Navigation and Controls', [
          basic('Hyper + H: Left arrow', from: hyper('h'), to: [to_key('left_arrow')]),
          basic('Hyper + J: Down arrow', from: hyper('j'), to: [to_key('down_arrow')]),
          basic('Hyper + K: Up arrow', from: hyper('k'), to: [to_key('up_arrow')]),
          basic('Hyper + L: Right arrow', from: hyper('l'), to: [to_key('right_arrow')]),
          basic('Hyper+Cmd + L: End of Line', from: cmd_hyper('l'), to: [to_key('right_arrow', modifiers: ['left_command'])]),
          basic('Hyper+Cmd + J: End of File', from: cmd_hyper('j'), to: [to_key('end', modifiers: ['left_command'])]),
          basic('Hyper + N: Move to space left', from: hyper('n'), to: [to_key('left_arrow', modifiers: ['right_command', 'right_control', 'right_option' ])]),
          basic('Hyper + M: Move to space right', from: hyper('m'), to: [to_key('right_arrow', modifiers: ['right_command', 'right_control', 'right_option' ])]),
          basic('Hyper + Y: Toggle fullscreen', from: hyper('y'), to: [to_key('return_or_enter', modifiers: ['right_control', 'right_option'])]),
          basic('Hyper + A: Toggle VoiceOver', from: hyper('a'), to: [to_key('f5', modifiers: ['right_command'])]),
          basic('Hyper + R: Toggle menubar', from: hyper('r'), to: [to_key('f2', modifiers: ['fn', 'left_control'])]),
          basic('Hyper + F: Open default application launcher', from: hyper('f'), to: [to_key('spacebar', modifiers: ['right_option'])]),
          basic("Hyper + ': Espanso search", from: hyper('quote'), to: [to_key('e', modifiers: ['right_command', 'right_shift'])]),
          basic('Hyper + 8: Spell correct via popclip', from: hyper('8'), to: [*to_key_then_wait('left_arrow', modifiers: ['right_option']), *to_key_then_wait('right_arrow', modifiers: ['right_option', 'right_shift']), to_key('u', modifiers: ['right_command', 'right_option', 'right_control'])])
        ]),
    rule('Hyper Key - Default Application Launchers', [
          basic('Hyper + W: Open default browser (Zen)', from: hyper('w'), to: [open('Zen')]),
          basic('Hyper + E: Open email client (eM Client)', from: hyper('e'), to: [open('eM Client')]),
          basic('Hyper + T: Open default terminal (Alacritty)', from: hyper('t'), to: [open('Alacritty')]),
          basic('Hyper + O: Open Note Taker (Obsidian)', from: hyper('o'), to: [open('Obsidian')]),
          basic('Hyper + S: Open Work Messages (Slack)', from: hyper('s'), to: [open('Slack')]),
        ]),
    rule('Hyper+Cmd Key - Application Launchers', [
          basic('Hyper+Cmd + H: Open Homerow', from: cmd_hyper('h'), to: [to_key('space', modifiers: ['right_command', 'right_shift'])]),
          basic('Hyper+Cmd + O: Open Orion', from: cmd_hyper('o'), to: [open('Orion')]),
          basic('Hyper+Cmd + W: Open Obsidian', from: cmd_hyper('w'), to: [open('Obsidian')]),
          basic('Hyper+Cmd + S: Open Signal', from: cmd_hyper('s'), to: [open('Signal Beta')]),
          basic('Hyper+Cmd + G: Open Gather', from: cmd_hyper('g'), to: [open('Gather')]),
          basic('Hyper+Cmd + F: Open Godspeed', from: cmd_hyper('f'), to: [open('Godspeed')]),
          basic('Hyper+Cmd + V: Open VLC', from: cmd_hyper('v'), to: [open('VLC')]),
          basic('Hyper+Cmd + B: Open Beeper', from: cmd_hyper('b'), to: [open('Beeper Desktop')]),
          basic('Hyper+Cmd + M: Open AI Chat', from: cmd_hyper('m'), to: [open('NaiveChat')]),
          basic('Hyper+Cmd + M: Open Nimble Commander', from: cmd_hyper('n'), to: [open('Nimble Commander')]),
          basic('Hyper+Cmd + R: Restart Karabiner Elements', from: cmd_hyper('r'), to: [to_notification('my_message', 'Resetting Karabiner Elements!'), to_shell('$HOME/.local/share/bin/karabiner_reset')]),
          basic('Hyper+Cmd + D: Open Discord', from: cmd_hyper('d'), to: [open('Discord')]),
          basic('Hyper+Cmd + Z: Open Zoom', from: cmd_hyper('z'), to: [open('zoom.us')]),
          basic('Hyper+Cmd + E: Open Zed', from: cmd_hyper('e'), to: [open('Zed')]),
          basic('Hyper+Cmd + C: Open Calendar', from: cmd_hyper('c'), to: [to_shell('open -a "$HOME/Applications/Calendar.app"')]),
          basic('Hyper+Cmd + P: Open Brave Browser', from: cmd_hyper('p'), to: [open('Brave Browser Beta')]),
          basic('Hyper+Cmd + P: Open Bitwarden', from: hyper('p'), to: [open('Bitwarden')]),
        ]),
    app_specific_rule('App-Specific: Alacritty Terminal', '^org\\.alacritty$', [
          basic('Alacritty: Hyper + D sends EOF (Ctrl+D)', from: hyper('d'), to: [to_key('d', modifiers: ['right_control'])]),
          basic('Alacritty: Hyper + U previous tab (Option+U)', from: hyper('u'), to: [to_key('u', modifiers: ['right_option'])]),
          basic('Alacritty: Hyper + I next tab (Option+I)', from: hyper('i'), to: [to_key('i', modifiers: ['right_option'])]),
          basic('Alacritty: Hyper + [ previous pane (Ctrl+[)', from: hyper('open_bracket'), to: [to_key('open_bracket', modifiers: ['left_command'])]),
          basic('Alacritty: Hyper + ] next pane (Ctrl+])', from: hyper('close_bracket'), to: [to_key('close_bracket', modifiers: ['left_command'])])
        ]),
    app_specific_rule('App-Specific: Obsidian and Zen Browser', ['^md\\.obsidian', '^app\\.zen-browser\\.zen'], [
          basic('Hyper + u in Obsidian/Zen move one tab left', from: hyper('u'), to: [to_key('open_bracket', modifiers: ['right_shift', 'right_command'])]),
          basic('Hyper + i in Obsidian/Zen move one tab right', from: hyper('i'), to: [to_key('close_bracket', modifiers: ['right_shift', 'right_command'])])
        ]),
    app_specific_rule('App-Specific: Zen Browser', '^app\\.zen-browser\\.zen', [
          basic('Cmd + Shift + P in Zen select and paste top Proton Pass result', from: from_key('p', mandatory: ['left_shift', 'left_command']), to: [*to_tab_then_wait(12), *to_key_then_wait('return_or_enter'), *to_key_then_wait('escape'), to_key('v', modifiers: ['command'])])
        ]),
    app_specific_rule('App-Specific: Beeper', '^com\\.automattic\\.beeper\\.desktop$',  [
          basic('Beeper: Hyper + U move up conversation (Cmd+Option+Up)', from: hyper('u'), to: [to_key('up_arrow', modifiers: ['right_option', 'right_command'])]),
          basic('Beeper: Hyper + I move down conversation (Cmd+Option+Down)', from: hyper('i'), to: [to_key('down_arrow', modifiers: ['right_option', 'right_command'])])
        ]),
    app_specific_rule('App-Specific: Signal', '^org\\.whispersystems\\.signal-desktop', [
          basic('Signal: Hyper + U move up conversation (Option+Up)', from: hyper('u'), to: [to_key('up_arrow', modifiers: ['right_option'])]),
          basic('Signal: Hyper + I move down conversation (Option+Down)', from: hyper('i'), to: [to_key('down_arrow', modifiers: ['right_option'])]),
          basic('Signal: Cmd + E archives current chat and moves to next', from: from_key('e', mandatory: ['left_command']), to: [to_key('a', modifiers: ['right_command', 'right_shift']), to_key('3', modifiers: ['right_command'])]),
          basic('Signal: Cmd + K starts new chat (Cmd+N)', from: from_key('k', mandatory: ['left_command']), to: [to_key('n', modifiers: ['right_command'])]),
          basic('Signal: Cmd + Shift + Enter select chat', from: from_key('return_or_enter', mandatory: ['left_command', 'left_shift']), to: [*to_tab_then_wait(3), *to_key_then_wait('return_or_enter'), to_key('return_or_enter')]),
          basic('Signal: Cmd + Shift + = react to last message', from: from_key('equal_sign', mandatory: ['left_command', 'left_shift']), to: [*to_tab_then_wait(3, modifiers: ['right_shift']), to_key('e', modifiers: ['right_shift', 'right_command'])]),
          basic('Signal: Cmd + Shift + r replies to last message', from: from_key('r', mandatory: ['left_command', 'left_shift']), to: [*to_tab_then_wait(4, modifiers: ['right_shift']), to_key('r', modifiers: ['right_shift', 'right_command'])]),
          basic('Signal: Command + O opens link', from: from_key('o', mandatory: ['left_command']), to: [*to_tab_then_wait(4, modifiers: ['left_shift']), to_key('return_or_enter')])
        ]),
    app_specific_rule('App-Specific: Godspeed', '^com\\.godspeedapp\\.Godspeed', [
          basic('Godspeed: Hyper + U move up (Option+P)', from: hyper('u'), to: [to_key('p', modifiers: ['right_option'])]),
          basic('Godspeed: Hyper + I move down (Option+N)', from: hyper('i'), to: [to_key('n', modifiers: ['right_option'])])
        ]),
    app_specific_rule('App-Specific: VLC Media Player', '^org\\.videolan\\.vlc$', [
          basic('VLC: Z skips backward (Left arrow)', from: from_key('z'), to: [to_key('left_arrow')]),
          basic('VLC: W toggles playback (Space)', from: from_key('w'), to: [to_key('spacebar')]),
          basic('VLC: X skips forward (Right arrow)', from: from_key('x'), to: [to_key('right_arrow')])
        ]),
    app_specific_rule('App-Specific: Safari', 'com.apple.Safari', [
          nested_manipulators('Disable Escape as exit fullscreen in Safari', [basic(from: from_key('escape'), to: [])])
        ]),
    rule('Hyper Key - Default Tab and Window Navigation', [
          basic('Hyper + U: Previous tab (Cmd+Option+Left)', from: hyper('u'), to: [to_key('left_arrow', modifiers: ['right_command', 'right_option'])]),
          basic('Hyper + I: Next tab (Cmd+Option+Right)', from: hyper('i'), to: [to_key('right_arrow', modifiers: ['right_command', 'right_option'])]),
          basic('Hyper + Cmd +  U: Play/Pause', from: cmd_hyper('u'), to: [to_key('play_or_pause')]),
          basic('Hyper + ;: Jump to last tab (Cmd+9)', from: hyper('semicolon'), to: [to_key('9', modifiers: ['right_command'])]),
          basic('Hyper + D: Close current tab (Cmd+W)', from: hyper('d'), to: [to_key('w', modifiers: ['right_command'])])
        ]),
    mouse_keys_rule
  ]
end

File.write(OUTPUT_PATH, JSON.pretty_generate(karabiner_config(rules)) + "\n")
