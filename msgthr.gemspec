# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>

Gem::Specification.new do |s|
  manifest = File.read('.manifest').split(/\n/)
  s.name = %q{msgthr}
  s.version = ENV['VERSION'] || '1.0.0'
  s.authors = ['msgthr hackers']
  s.summary = 'container-agnostic, non-recursive message threading'
  s.description = File.read('README').split(/\n\n/)[1].strip
  s.email = %q{msgthr-public@80x24.org}
  s.homepage = 'https://80x24.org/msgthr/'
  s.executables = []
  s.files = manifest
  s.licenses = 'GPL-2.0+'
  s.required_ruby_version = '>= 1.9.3'
end
