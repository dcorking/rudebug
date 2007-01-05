class RuDebug::Page
  attr_reader :session, :glade_file

  def initialize(parent, session)
    @parent = parent
    @session = session
    @glade_file = parent.glade_file

    @glade = GladeXML.new(@glade_file, "session-hpaned") do |handler|
      method(handler) rescue lambda { |*args| p [handler, *args] }
    end

    @page = @glade["session-hpaned"]

    initialize_browser()
    initialize_source_code()
    initialize_shell()

    load_browser()
    load_current_code()

    label = Gtk::Label.new(session.title)
    @parent.notebook.prepend_page(@page, label)
  end

  def create_default_tag(buffer, size = nil, more = {})
    size ||= 10
    options = { "font" => "Andale Mono %d" % size }.merge(more)
    buffer.create_tag("default", options)
  end

  def generic_step(method)
    result = @session.__send__(method)

    if result.nil? then
      close()
    else
      update_location(*result)
      load_browser()
      title = result.join(":") # TODO: Query from server?
      update_title(title)
    end

    return result
  end

  def update_title(title)
    @parent.notebook.set_tab_label_text(@page, title)
    @parent.notebook.set_menu_label_text(@page, title)
    @parent.pages[title] = self
  end

  def continue()
    generic_step(:continue)
  end
  
  def step_into()
    generic_step(:step_into)
  end
  
  def step_over()
    generic_step(:step_over)
  end
  
  def close()
    page_num = @parent.notebook.page_num(@page)
    if page_num != -1 then
      @parent.notebook.remove_page(page_num)
    end
  end
end

require 'rudebug/page/shell'
require 'rudebug/page/source_code'
require 'rudebug/page/browser'
