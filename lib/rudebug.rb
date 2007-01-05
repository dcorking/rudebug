begin
  require 'rubygems'
rescue LoadError
  # RubyGems not installed
end

DATA_PATH = File.expand_path(File.dirname(__FILE__))

require 'gtk2'
require 'libglade2'
require 'yaml'

require 'rudebug/main'
