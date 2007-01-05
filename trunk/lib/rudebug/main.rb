require 'rudebug/gtk-patch'

class RuDebug
  attr_reader :glade_file, :window, :notebook

  def initialize(glade_file)
    load_config()

    @glade_file = glade_file
    @glade = GladeXML.new(glade_file) do |handler|
      method(handler) rescue lambda { |*args| p [handler, *args] }
    end

    @window = @glade["main-window"]
    @notebook = @glade["session-notebook"]
    @notebook.homogeneous = false
    @notebook.remove_page(0)
    @notebook.show_tabs = false
    @pages = {}

    initialize_connect()

    @window.show
  end

  def config_path()
    base_path = ENV["APPDATA"] || File.expand_path("~")
    File.join(base_path, ".rudebug_conf")
  end

  def load_config()
    @config = begin
      YAML.load(File.read(config_path)).to_hash
    rescue Exception
      {}
    end
  end

  def save_config()
    save_connect_servers()

    File.open(config_path, "w") do |file|
      file.puts(@config.to_yaml)
    end
  rescue Exception
    # Ignored
  end

  def on_main_window_destroy()
    save_config()
    Gtk.main_quit()
  end
  alias :on_quit_activate :on_main_window_destroy
end

require 'rudebug/page'
require 'rudebug/connect'
require 'rudebug/highlight'

Gtk.init
rudebug = RuDebug.new(File.join(DATA_PATH, "rudebug.glade"))
Gtk.main
