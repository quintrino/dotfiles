# frozen_string_literal: true

def latest(language)
  `asdf plugin-add #{language} 2> /dev/null`
  versions = `asdf list-all #{language} 2> /dev/null`.split("\n")
  mri_versions = versions.select { |v| v.count('a-zA-Z').zero? }
  mri_versions.max_by { |v| Gem::Version.new(v) }
end

def latest_available(language)
  versions = `asdf list #{language} 2> /dev/null`.split("\n")
  mri_versions = versions.select { |v| v.count('a-zA-Z').zero? }
  latest = mri_versions.max_by { |v| Gem::Version.new(v) }
  return '' unless latest

  latest.strip
end
