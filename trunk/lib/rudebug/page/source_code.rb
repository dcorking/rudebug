require 'rudebug/page/code_file'

class RuDebug::Page
  attr_reader :files_combobox, :code_notebook

  def initialize_source_code()
    @code_notebook = @glade["code-notebook"]
    @files_combobox = @glade["code-combobox"]
    model = @files_combobox.model
    model.set_default_sort_func do |iter1, iter2|
      iter1[0].downcase <=> iter2[0].downcase
    end
    model.set_sort_column_id(Gtk::TreeSortable::DEFAULT_SORT_COLUMN_ID)

    @code_notebook.remove_page(0)
    @files = {}
  end

  def on_code_combobox_changed(combobox)
    name = combobox.active_text
    @files[name].activate
  end

  def activate_file(name)
    activate_idx = nil
    @files_combobox.model.each_with_index do |(model, path, iter), idx|
      activate_idx = idx if iter[0] == name
    end

    @files_combobox.active = activate_idx if activate_idx
  end

  def update_location(name, line)
    file = @files[name] ||= CodeFile.new(self, name)
    file.place_marker(line)
    activate_file(name)
  end

  def load_current_code()
    name = @session.current_file
    line = @session.current_line
    
    update_location(name, line)
  end

  def highlight_inspect(string, buffer, condition = true)
    # Heuristics ftw!
    if condition and string[0, 1] != "#" then
      Syntax.gtk_highlight(string, buffer)
    else
      buffer.insert(buffer.end_iter, string, "default")
    end
  end
end
