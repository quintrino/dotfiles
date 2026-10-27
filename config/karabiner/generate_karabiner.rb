#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'shellwords'

HYPER = %w[right_shift right_control right_command right_option].freeze
HYPER_CMD = (HYPER + %w[left_command]).freeze
HYPER_OPT = (HYPER + %w[left_option]).freeze
HYPER_SHIFT_CMD = (HYPER_CMD + %w[left_shift]).freeze
SS_FORMAT = '$HOME/Proton/Sync/Devices/Screenshots/Screenshot_'

OUTPUT_PATH = File.expand_path('karabiner.json', __dir__)

# One JSON object per line, written when a logged rule fires. See `logger`.
HISTORY_PATH = '$HOME/.local/share/karabiner/history.jsonl'

# How app_specific_rule names an app, by the bundle identifier (or regex) it is given: `name`
# in the history, `label` in front of the rule's description in Karabiner. A new app-specific
# rule needs an entry here.
APP_NAMES = {
  'com.jins.naivechat' => { name: 'naivechat', label: 'NaiveChat' },
  'org.alacritty' => { name: 'alacritty', label: 'Alacritty' },
  'md.obsidian' => { name: 'obsidian', label: 'Obsidian' },
  'app.zen-browser.zen' => { name: 'zen', label: 'Zen' },
  'com.automattic.beeper.desktop' => { name: 'beeper', label: 'Beeper' },
  'org.whispersystems.signal-desktop' => { name: 'signal', label: 'Signal' },
  'com.godspeedapp.Godspeed' => { name: 'godspeed', label: 'Godspeed' },
  'org.videolan.vlc' => { name: 'vlc', label: 'VLC' },
  'com.apple.Safari' => { name: 'safari', label: 'Safari' }
}.freeze

NUMPAD_LAYER = {
  'u' => '7', 'i' => '8', 'o' => '9',
  'j' => '4', 'k' => '5', 'l' => '6',
  'm' => '1', 'comma' => '2', 'period' => '3',
  'p' => '0'
}.freeze

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

# `app` is one bundle identifier, or several. With several, every manipulator is repeated for
# each app, so each copy has its own condition and its own history line. Write the manipulator
# descriptions without the app: the label is put in front of them here, and the history gets
# the app as a field.
def app_specific_rule(description, app, manipulators)
  manipulators_with_app = [app].flatten.flat_map do |bundle_identifier|
    info = APP_NAMES.fetch(bundle_identifier) { raise "APP_NAMES has no entry for #{bundle_identifier}" }
    manipulators.map { |m| app_manipulator(m, bundle_identifier, info) }
  end

  rule(description, manipulators_with_app)
end

def app_manipulator(manipulator, bundle_identifier, info)
  changes = { 'conditions' => Array(manipulator['conditions']) + [app_if([bundle_identifier])] }
  changes['description'] = "#{info[:label]}: #{manipulator['description']}" if manipulator['description']
  if history_logged?(manipulator)
    changes['to_after_key_up'] = logger(manipulator['from'], manipulator['description'], true, apps: [info[:name]])
  end
  manipulator.merge(changes)
end

# `from` is a from_key hash (hyper('e'), from_key(...)) or a bare key code ('l'), which is
# shorthand for from_key('l'). Inside leader(), basic is used as-is: leader() adds the
# condition and the clean-up to the manipulators it is given.
def basic(description = nil, from:, to:, to_if_alone: nil, to_after_key_up: nil, to_delayed_action: nil, conditions: nil, parameters: nil, log: true, kind: 'key')
  from = from_key(from) if from.is_a?(String)
  compact_hash(
    'description' => description,
    'from' => from,
    'to' => to,
    'to_if_alone' => to_if_alone,
    'to_after_key_up' => logger(from, description, log, kind: kind),
    'to_delayed_action' => to_delayed_action,
    'conditions' => conditions,
    'parameters' => parameters,
    'type' => 'basic'
  )
end

def to_delayed_action(invoked:, canceled: [])
  { 'to_if_invoked' => invoked, 'to_if_canceled' => canceled }
end

# A leader key: press `trigger`, then one of the keys in `bindings`. A binding is a basic(...)
# manipulator, or another leader(...) that opens a further level, to any depth. Any other key,
# or waiting longer than `timeout` milliseconds, cancels. A bare key code in a binding's
# `from` also matches while the Hyper modifiers are still held, as they are when the trigger is
# a hyper(...) key.
#
# `description` names the leader in Karabiner and in the history, which reads
# "Leader: Hyper + W:O: Open Obsidian", or "Leader: Hyper + W:G:H: Open GitHub" from a nested one.
#
#   leader('Hyper + W', hyper('w'), [
#     basic('Open Obsidian', from: 'o', to: [open('Obsidian')]),
#     basic('Open email', from: hyper('e'), to: [open('eM Client')]),
#     leader('Git', 'g', [
#       basic('Open GitHub', from: 'h', to: [open('GitHub Desktop')])
#     ])
#   ])
#
# Put the rule above any rule that uses the same keys: the first match wins.
# A rule that also remembers what it was built from, so that, used as a binding inside another
# leader, it can become a level of that leader instead.
class LeaderRule < Hash
  attr_accessor :spec
end

def leader(description, trigger, bindings, timeout: 1500)
  label = "Leader: #{description}"
  variable = "leader_#{leader_key_id(trigger)}"

  leader_rule = LeaderRule[rule(label, [
    leader_start(label, leader_from_key(trigger), variable, nil, timeout),
    *leader_level(bindings, label, variable, timeout, [history_name(leader_from_key(trigger))])
  ])]
  leader_rule.spec = { description: description, trigger: trigger, bindings: bindings, timeout: timeout }
  leader_rule
end

def leader_clear(variable)
  [to_variable(variable, 0), to_notification(variable, '')]
end

# Moves into the level `variable`, and back out if nothing is pressed within `timeout`.
# `leaving` is the level it came from, if any.
def leader_start(label, from, variable, leaving, timeout)
  basic("#{label}: start", log: false, from: from,
        conditions: leaving && [variable_if(leaving, 1)],
        to: [*(leaving && leader_clear(leaving)), to_variable(variable, 1),
             to_notification(variable, "#{label}…", duration: timeout)],
        to_delayed_action: to_delayed_action(invoked: leader_clear(variable)),
        parameters: { 'basic.to_delayed_action_delay_milliseconds' => timeout })
end

# The manipulators for the keys of one level, then the cancel for it. `label` is the path so
# far, such as "Leader: Hyper + W:G". `path` is the same path as keys, for the history.
def leader_level(bindings, label, variable, timeout, path)
  manipulators = bindings.flat_map do |binding|
    if binding.is_a?(LeaderRule)
      leader_nested_manipulators(binding.spec, label, variable, path)
    else
      [leader_binding(binding, label, variable, path)]
    end
  end

  [
    *manipulators,
    basic("#{label}: cancel", log: false,
          from: { 'any' => 'key_code', 'modifiers' => { 'optional' => ['any'] } },
          to: leader_clear(variable), conditions: [variable_if(variable, 1)])
  ]
end

def leader_nested_manipulators(spec, label, variable, keys)
  from = leader_from(leader_from_key(spec[:trigger]))
  path = "#{label}:#{leader_key_name(from)}"
  inner = "#{variable}_#{leader_key_id(from)}"

  [
    leader_start("#{path} (#{spec[:description]})", from, inner, variable, spec[:timeout]),
    *leader_level(spec[:bindings], path, inner, spec[:timeout], [*keys, history_name(leader_from_key(spec[:trigger]))])
  ]
end

def leader_from_key(key)
  key.is_a?(String) ? from_key(key) : key
end

# A key without modifiers of its own still matches while Hyper is held
def leader_from(from)
  from['modifiers'] ? from : from.merge('modifiers' => { 'optional' => ['any'] })
end

# Keys of a trigger or binding, for variable names and for the history. A chord has several.
def leader_key_codes(from)
  from['simultaneous'] ? from['simultaneous'].map { |key| key['key_code'] } : [from['key_code']]
end

def leader_key_id(from)
  leader_key_codes(from).join('_')
end

def leader_key_name(from)
  leader_key_codes(from).map { |key_code| key_code.to_s.upcase }.join('+')
end

# The description, and so the history line, says it came from the leader. A binding that
# was written with log: false stays unlogged.
def leader_binding(binding, label, variable, path)
  from = leader_from(binding['from'])
  description = "#{label}:#{leader_key_name(from)}: #{binding['description']}"
  keys = [*path, history_name(binding['from'])]
  binding.merge(
    'description' => description,
    'to_after_key_up' => binding['to_after_key_up'] && logger(binding['from'], binding['description'], true, kind: 'leader', path: keys),
    'from' => from,
    'to' => [*binding['to'], *leader_clear(variable)],
    'conditions' => [*binding['conditions'], variable_if(variable, 1)]
  )
end

# The modifiers, the key and whether any other modifiers are also accepted, read from a `from`
# so the history never depends on what a description says. Hyper is all four right-hand modifiers.
def history_combo(from)
  modifiers = from['modifiers'] || {}
  mandatory = modifiers['mandatory'] || []
  hyper = (HYPER - mandatory).empty?
  mods = (hyper ? mandatory - HYPER : mandatory).sort
  mods.unshift('hyper') if hyper
  key = from['simultaneous'] ? leader_key_codes(from).join('&') : (from['key_code'] || from['any'])
  [mods, key, (modifiers['optional'] || []).include?('any')]
end

# "hyper+left_command+f". A chord joins its keys with &: "left_command&right_command".
def history_name(from)
  mods, key, = history_combo(from)
  [*mods, key].join('+')
end

# What one history line says about a rule firing, except the time. `id` is the scope and the
# combo: "global:hyper+f", "alacritty:hyper+u", "zen:hyper+u", "mouse:q&j",
# "leader:left_command&right_command>w". It follows the keys, so rewording a description or
# changing the action keeps the history joined up.
#
#   kind: 'key' (the default), 'mouse' for mouse keys mode, 'leader' for a key in a leader.
#   apps: names from APP_NAMES. Empty means every app.
#   path: for a leader, every key from the trigger down to this one. It makes up the id, and is
#         not a field of its own: "leader:hyper+w>g>h" is the trigger, then g, then h.
#
# `mods` are Karabiner's own names, Hyper first: ["hyper", "left_command", "left_shift"].
# optional_any is true when the rule also fires with other modifiers held (open_hyper): it is
# still Hyper + L, whatever else is down.
def history_record(from, description, apps: [], kind: 'key', path: nil)
  mods, key, optional_any = history_combo(from)
  combo = [*mods, key].join('+')
  id = case kind
       when 'leader' then "leader:#{path.join('>')}"
       when 'mouse' then "mouse:#{combo}"
       else "#{apps.empty? ? 'global' : apps.join('|')}:#{combo}"
       end
  {
    'id' => id, 'type' => kind, 'apps' => apps, 'mods' => mods, 'key' => key,
    'optional_any' => optional_any, 'desc' => description
  }
end

def shell_quote(text)
  "'" + text.gsub("'") { "'\\''" } + "'"
end

# Appends one JSON object per line: "ts" (ISO 8601 with offset) and "hts" (what `date` prints)
# come from a single reading of the clock, then the fields of the record. The record is quoted
# for the shell here, so a description may contain any character.
def history_command(record)
  iso = %q(date -r "$now" +%Y-%m-%dT%H:%M:%S%z | sed -E 's/([0-9]{2})$/:\1/')
  fields = shell_quote(JSON.generate(record)[1..-2])
  "now=$(date +%s); printf '{\"ts\":\"%s\",\"hts\":\"%s\",%s}\\n' \"$(#{iso})\" \"$(date -r \"$now\")\" #{fields} >> \"#{HISTORY_PATH}\""
end

# Nothing is logged for a manipulator with no description, or with log: false.
def logger(from, description, log, apps: [], kind: 'key', path: nil)
  return nil unless log && description

  [{ 'shell_command' => history_command(history_record(from, description, apps: apps, kind: kind, path: path)) }]
end

def history_logged?(manipulator)
  Array(manipulator['to_after_key_up']).any? { |action| action['shell_command'].to_s.include?(HISTORY_PATH) }
end

def nested_manipulators(description = nil, manipulators)
  compact_hash('description' => description, 'manipulators' => manipulators)
end

def from_key(key_code, mandatory: nil, optional: nil)
  modifiers = compact_hash('mandatory' => mandatory, 'optional' => optional)
  compact_hash('key_code' => key_code, 'modifiers' => modifiers.empty? ? nil : modifiers)
end

def hyper(key_code, extra_modifiers = {})
  modifiers = compact_hash('mandatory' => HYPER).merge(extra_modifiers)
  compact_hash('key_code' => key_code, 'modifiers' => modifiers)
end

def cmd_hyper(key_code)
  modifiers = compact_hash('mandatory' => HYPER_CMD)
  compact_hash('key_code' => key_code, 'modifiers' => modifiers)
end

def open_hyper(key_code)
  modifiers = compact_hash('mandatory' => HYPER, 'optional' => ['any'])
  compact_hash('key_code' => key_code, 'modifiers' => modifiers)
end

def cmd_shift_hyper(key_code)
  modifiers = compact_hash('mandatory' => HYPER_SHIFT_CMD)
  compact_hash('key_code' => key_code, 'modifiers' => modifiers)
end

# Several keys pressed together, in either order. Used as a leader trigger.
def from_chord(*key_codes)
  {
    'simultaneous' => key_codes.map { |key_code| { 'key_code' => key_code } },
    'modifiers' => { 'optional' => ['any'] }
  }
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

# def open(app)
#   { 'shell_command' => "open -a '" + app + ".app'"}
# end

def open(app)
  { "software_function" => {
      "open_application" => {
          "file_path": "/Applications/#{app}.app"
      }
    }
  }
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

def to_notification(id, text, duration: 2000)
  { 'set_notification_message' => { 'id' => id, 'text' => text, 'duration_milliseconds' => duration } }
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
    kind: 'mouse',
    from: from_key(key_code, optional: ['any']),
    to: actions,
    conditions: conditions,
    to_after_key_up: to_after_key_up
  )
end

def mouse_keys_chord(key_code, actions, to_after_key_up: nil)
  basic(
    'Mouse chord: ' + key_code,
    kind: 'mouse',
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

def numpad_layer_rule
  rule(
    'Fn + Shift - Numpad Layer',
    NUMPAD_LAYER.map do |from_code, digit|
      basic(
        "Fn+Shift + #{from_code}: #{digit}",
        from: from_key(from_code, mandatory: %w[left_shift fn]),
        to: [to_key(digit)],
        log: false
      )
    end
  )
end

def rules
  [
    app_specific_rule('App-Specific: NaiveChat', 'com.jins.naivechat', [
          basic('NaiveChat: Escape returns to previous app', log: false, from: from_key('caps_lock'), to: [*to_key_then_wait('escape'), to_shell('/usr/local/bin/aerospace workspace-back-and-forth')])
      ]),
    rule('System Modifications - Caps Lock to Hyper Key with Escape on tap', [
          basic('Shift + Caps Lock enables actual Caps Lock', from: from_key('caps_lock', mandatory: ['shift'], optional: ['caps_lock']), to: [to_key('caps_lock')], log: false),
          basic('Caps Lock to Hyper Key (Right Shift + Right Cmd + Right Ctrl + Right Option), Escape on tap', from: from_key('caps_lock', optional: ['any']), to: [to_key('right_shift', modifiers: ['right_command', 'right_control', 'right_option'])], to_if_alone: [to_key('escape')], log: false),
          basic('Left Shift to backspace on tap', from: from_key('right_shift', mandatory: ['left_shift']), to: [to_key('delete_or_backspace')])
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
          basic('Hyper + H: Left arrow', from: open_hyper('h'), to: [to_key('left_arrow')]),
          basic('Hyper + J: Down arrow', from: open_hyper('j'), to: [to_key('down_arrow')]),
          basic('Hyper + K: Up arrow', from: open_hyper('k'), to: [to_key('up_arrow')]),
          basic('Hyper + L: Right arrow', from: open_hyper('l'), to: [to_key('right_arrow')]),
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
          basic('Hyper + P: Open Password Manager (Bitwarden)', from: hyper('p'), to: [open('Bitwarden')])
        ]),
    rule('Hyper+Cmd Key - Application Launchers', [
          basic('Hyper+Cmd + H: Open Homerow', from: cmd_hyper('h'), to: [to_key('space', modifiers: ['right_command', 'right_shift'])]),
          basic('Hyper+Cmd + O: Open Orion', from: cmd_hyper('o'), to: [open('Orion')]),
          basic('Hyper+Cmd + W: Open Obsidian', from: cmd_hyper('w'), to: [open('Obsidian')]),
          basic('Hyper+Cmd + S: Open Signal', from: cmd_hyper('s'), to: [open('Signal Beta')]),
          basic('Hyper+Cmd + G: Open Gather', from: cmd_hyper('g'), to: [open('Gather')]),
          basic('Hyper+Cmd + F: Open Godspeed', from: cmd_hyper('f'), to: [open('Godspeed')]),
          basic('Hyper+Cmd + V: Open Video Player', from: cmd_hyper('v'), to: [open('IINA')]),
          basic('Hyper+Cmd + B: Open Beeper', from: cmd_hyper('b'), to: [open('Beeper Desktop')]),
          basic('Hyper+Cmd + M: Open AI Chat', from: cmd_hyper('m'), to: [open('NaiveChat')]),
          basic('Hyper+Cmd + M: Open Nimble Commander', from: cmd_hyper('n'), to: [open('Nimble Commander')]),
          basic('Hyper+Cmd + R: Restart Karabiner Elements', from: cmd_hyper('r'), to: [to_notification('my_message', 'Resetting Karabiner Elements!'), to_shell('$HOME/.local/share/bin/karabiner_reset')]),
          basic('Hyper+Cmd + D: Open Discord', from: cmd_hyper('d'), to: [open('Discord')]),
          basic('Hyper+Cmd + Z: Open Zoom', from: cmd_hyper('z'), to: [open('zoom.us')]),
          basic('Hyper+Cmd + E: Open Zed', from: cmd_hyper('e'), to: [open('Zed')]),
          basic('Hyper+Cmd + C: Open Calendar', from: cmd_hyper('c'), to: [to_shell('open -a "$HOME/Applications/Calendar.app"')]),
          basic('Hyper+Cmd + P: Open Brave Browser', from: cmd_hyper('p'), to: [open('Brave Browser Beta')])
        ]),
    app_specific_rule('App-Specific: Alacritty Terminal', 'org.alacritty', [
          basic('Hyper + D sends EOF (Ctrl+D)', from: hyper('d'), to: [to_key('d', modifiers: ['right_control'])]),
          basic('Hyper + U previous tab (Option+U)', from: hyper('u'), to: [to_key('u', modifiers: ['right_option'])]),
          basic('Hyper + I next tab (Option+I)', from: hyper('i'), to: [to_key('i', modifiers: ['right_option'])]),
          basic('Hyper + [ previous pane (Ctrl+[)', from: hyper('open_bracket'), to: [to_key('open_bracket', modifiers: ['left_command'])]),
          basic('Hyper + ] next pane (Ctrl+])', from: hyper('close_bracket'), to: [to_key('close_bracket', modifiers: ['left_command'])])
        ]),
    app_specific_rule('App-Specific: Obsidian and Zen Browser', ['md.obsidian', 'app.zen-browser.zen'], [
          basic('Hyper + u move one tab left', from: hyper('u'), to: [to_key('open_bracket', modifiers: ['right_shift', 'right_command'])]),
          basic('Hyper + i move one tab right', from: hyper('i'), to: [to_key('close_bracket', modifiers: ['right_shift', 'right_command'])]),
          basic('Hyper+Cmd + J: End of File', from: cmd_hyper('j'), to: [to_key('end', modifiers: ['left_command'])])
        ]),
    app_specific_rule('App-Specific: Zen Browser', 'app.zen-browser.zen', [
          basic('Cmd + Shift + P select and paste top Proton Pass result', from: from_key('p', mandatory: ['left_shift', 'left_command']), to: [*to_tab_then_wait(12), *to_key_then_wait('return_or_enter'), *to_key_then_wait('escape'), to_key('v', modifiers: ['command'])])
        ]),
    app_specific_rule('App-Specific: Beeper', 'com.automattic.beeper.desktop',  [
          basic('Hyper + U move up conversation (Cmd+Option+Up)', from: hyper('u'), to: [to_key('up_arrow', modifiers: ['right_option', 'right_command'])]),
          basic('Hyper + I move down conversation (Cmd+Option+Down)', from: hyper('i'), to: [to_key('down_arrow', modifiers: ['right_option', 'right_command'])])
        ]),
    app_specific_rule('App-Specific: Signal', 'org.whispersystems.signal-desktop', [
          basic('Hyper + U move up conversation (Option+Up)', from: hyper('u'), to: [to_key('up_arrow', modifiers: ['right_option'])]),
          basic('Hyper + I move down conversation (Option+Down)', from: hyper('i'), to: [to_key('down_arrow', modifiers: ['right_option'])]),
          basic('Cmd + E archives current chat and moves to next', from: from_key('e', mandatory: ['left_command']), to: [to_key('a', modifiers: ['right_command', 'right_shift']), to_key('3', modifiers: ['right_command'])]),
          basic('Cmd + K starts new chat (Cmd+N)', from: from_key('k', mandatory: ['left_command']), to: [to_key('n', modifiers: ['right_command'])]),
          basic('Cmd + Shift + Enter select chat', from: from_key('return_or_enter', mandatory: ['left_command', 'left_shift']), to: [*to_tab_then_wait(3), *to_key_then_wait('return_or_enter'), to_key('return_or_enter')]),
          basic('Cmd + Shift + = react to last message', from: from_key('equal_sign', mandatory: ['left_command', 'left_shift']), to: [*to_tab_then_wait(3, modifiers: ['right_shift']), to_key('e', modifiers: ['right_shift', 'right_command'])]),
          basic('Cmd + Shift + r replies to last message', from: from_key('r', mandatory: ['left_command', 'left_shift']), to: [*to_tab_then_wait(4, modifiers: ['right_shift']), to_key('r', modifiers: ['right_shift', 'right_command'])]),
          basic('Command + O opens link', from: from_key('o', mandatory: ['left_command']), to: [*to_tab_then_wait(6, modifiers: ['left_shift']), to_key('return_or_enter')])
        ]),
    app_specific_rule('App-Specific: Godspeed', 'com.godspeedapp.Godspeed', [
          basic('Hyper + U move up (Option+P)', from: hyper('u'), to: [to_key('p', modifiers: ['right_option'])]),
          basic('Hyper + I move down (Option+N)', from: hyper('i'), to: [to_key('n', modifiers: ['right_option'])])
        ]),
    app_specific_rule('App-Specific: VLC Media Player', 'org.videolan.vlc', [
          basic('Z skips backward (Left arrow)', from: from_key('z'), to: [to_key('left_arrow')]),
          basic('W toggles playback (Space)', from: from_key('w'), to: [to_key('spacebar')]),
          basic('X skips forward (Right arrow)', from: from_key('x'), to: [to_key('right_arrow')])
        ]),
    app_specific_rule('App-Specific: Safari', 'com.apple.Safari', [
          nested_manipulators('Disable Escape as exit fullscreen',[basic(from: from_key('escape'), to: [])])
        ]),
    rule('Hyper Key - Default Tab and Window Navigation', [
          basic('Hyper + U: Previous tab (Cmd+Option+Left)', from: hyper('u'), to: [to_key('left_arrow', modifiers: ['right_command', 'right_option'])]),
          basic('Hyper + I: Next tab (Cmd+Option+Right)', from: hyper('i'), to: [to_key('right_arrow', modifiers: ['right_command', 'right_option'])]),
          basic('Hyper + Cmd +  U: Play/Pause', from: cmd_hyper('u'), to: [to_key('play_or_pause')]),
          basic('Hyper + ;: Jump to last tab (Cmd+9)', from: hyper('semicolon'), to: [to_key('9', modifiers: ['right_command'])]),
          basic('Hyper + D: Close current tab (Cmd+W)', from: hyper('d'), to: [to_key('w', modifiers: ['right_command'])])
        ]),
    mouse_keys_rule,
    numpad_layer_rule,
    leader('Double Command', from_chord('left_command', 'right_command'), [
      basic('Open Zen', from: 'w', to: [open('Zen')]),
      basic('Open Obsidian', from: 'o', to: [open('Obsidian')])
    ])
  ]
end

File.write(OUTPUT_PATH, JSON.pretty_generate(karabiner_config(rules)) + "\n")
