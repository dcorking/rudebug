class RuDebug::Page
  def initialize_shell()
    @shell_out_view = @glade["shell-out-view"]
    @shell_out = @shell_out_view.buffer
    @shell_in = @glade["shell-in-entry"]
    @shell_in.grab_focus

    create_default_tag(@shell_out, 12)

    @shell_out.insert(@shell_out.end_iter,
      "Interactive session shell for %s" % @session.title, "default")
    @shell_out_view.cursor_visible = false
    @shell_out_end = @shell_out.create_mark(nil, @shell_out.end_iter, false)

    @shell_history = []
    @shell_history_idx = -1
    @shell_history_ignore_change = false
  end

  def on_shell_in_button_pressed(button)
    input = @shell_in.text

    result = begin
      @session.eval(input)
    rescue Connection::RemoteException => exception
      error = true
      exception.message
    end

    @shell_out.insert(@shell_out.end_iter, "\n\n>> ", "default")
    Syntax.gtk_highlight(input, @shell_out)

    marker = error ? "" : "=> "

    @shell_out.insert(@shell_out.end_iter, "\n%s" % marker, "default")
    highlight_inspect(result, @shell_out, !error)

    @shell_out_view.scroll_to_mark(@shell_out_end, 0, true, 1, 1)
    @shell_in.text = ""

    @shell_history.unshift(input)
    @shell_history.uniq!
  end
  alias :on_shell_in_entry_activate :on_shell_in_button_pressed

  def on_shell_in_entry_key_press_event(shell_in, event)
    case event.keyval
      when Gdk::Keyval::GDK_Up then
        if @shell_history.size > 0 then
          if @shell_history_idx == -1 then
            text = @shell_in.text
          
            if !text.strip.empty? then
              old_size = @shell_history.size
              @shell_history.unshift(text)
              @shell_history.uniq!
              @shell_history_idx += 1 if old_size != @shell_history.size
            end
          end

          @shell_history_idx += 1 if @shell_history_idx < @shell_history.size - 1
          shell_in_change_text(@shell_history[@shell_history_idx])
        end

      when Gdk::Keyval::GDK_Down then
        if @shell_history_idx > 0 then
          @shell_history_idx -= 1
          shell_in_change_text(@shell_history[@shell_history_idx])
        end

      else
        return false
    end

    return true
  end

  def shell_in_change_text(text)
    @shell_history_ignore_change = true
    @shell_in.text = text
    @shell_in.position = -1
  ensure
    @shell_history_ignore_change = false
  end

  def on_shell_in_entry_changed(shell_in)
    unless @shell_history_ignore_change
      @shell_history_idx = -1
    end
  end
end
