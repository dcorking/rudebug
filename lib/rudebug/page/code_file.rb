class RuDebug::Page::CodeFile
  def initialize(parent, name)
    @parent = parent
    @name = name
    @glade_file = parent.glade_file

    @parent.files_combobox.prepend_text(name)
    update_combobox_sensitive()

    @glade = GladeXML.new(@glade_file, "code-container") do |handler|
      method(handler) rescue lambda { |*args| p [handler, *args] }
    end

    @code = @glade["code-container"]
    @code_viewport = @glade["code-viewport"]

    label = Gtk::Label.new(name)
    @parent.code_notebook.prepend_page(@code, label)

    @line_view = @glade["line-view"]
    @code_view = @glade["code-view"]
    @line_buf = @line_view.buffer
    @code_buf = @code_view.buffer

    @parent.create_default_tag(@line_buf)
    @parent.create_default_tag(@code_buf)

    @pos_marker = @code.render_icon(
      Gtk::Stock::GO_FORWARD, Gtk::IconSize::MENU, "foo")
    @last_marker_line = nil

    load_source_code()
  end

  def activate()
    @parent.code_notebook.page = @parent.code_notebook.page_num(@code)
  end

  def update_combobox_sensitive()
    @parent.files_combobox.sensitive = @parent.files_combobox.model.size > 0
  end

  def load_source_code()
    source = @parent.session.source_code(@name)
    Syntax.gtk_highlight(source, @code_buf)

    line_no = source.to_a.size
    lines = (1 .. line_no).map do |line|
      "%*d" % [line_no.to_s.size, line]
    end.join("\n")
    @line_buf.insert(@line_buf.end_iter, lines, "default")
    @line_count = line_no - 1
  end

  def place_marker(line)
    line -= 1

    if @last_marker_line then
      start_iter = @line_buf.get_iter_at_line(@last_marker_line)
      end_iter = @line_buf.get_iter_at_line(@last_marker_line)
      end_iter.forward_chars(2)
      @line_buf.delete(start_iter, end_iter)
    end

    iter = @line_buf.get_iter_at_line(line)
    @line_buf.insert(iter, " ")
    @line_buf.insert(iter, @pos_marker)
    @last_marker_line = line

    vadj = @code_viewport.vadjustment

    # Got to delay this until the source view actually is done loading...
    Thread.new do
      sleep 0.01 until vadj.upper > 1.0 if @line_count > 2

      vadj.value = [
        vadj.upper * (line / @line_count.to_f),
        vadj.upper - vadj.page_size
      ].min
    end
  end


  def on_code_view_button_release_event()
    
  end
  alias :on_line_view_button_release_event :on_code_view_button_release_event
end

