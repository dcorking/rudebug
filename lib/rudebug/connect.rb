require 'rudebug/connection'

class RuDebug
  attr_reader :pages

  def initialize_connect()
    @connect_dlg = @glade["connect-dialog"]
    @connectdlg_entry = @glade["connectdlg-server-entry"]
    @connectdlg_type = @glade["connectdlg-type-combobox"]
    @connectdlg_btn = @glade["connectdlg-button"]

    load_connect_servers()

    @connect_btn = @glade["connect-button"]
    @disconnect_btn = @glade["disconnect-button"]
    @continue_btn = @glade["continue-button"]
    @step_into_btn = @glade["step-into-button"]
    @step_over_btn = @glade["step-over-button"]

    @connect_menuitem = @glade["connect-menuitem"]
    @disconnect_menuitem = @glade["disconnect-menuitem"]

    @connection_status = @glade["status-label"]
    @connect_dlg.transient_for = @window

    @connect_page = @notebook.get_nth_page(0)
    @not_connected = @connection_status.text
    @connection = nil
  end

  def load_connect_servers()
    default_servers = [
      "localhost:8989",
      "druby://localhost:42531"
    ]

    conf_servers = @config[:servers].to_ary rescue []
    servers = (conf_servers + default_servers).uniq

    servers.each do |server|
      @connectdlg_entry.append_text(server)
    end

    @connectdlg_entry.active = 0
  end

  def save_connect_servers()
    servers = []
    @connectdlg_entry.model.each do |model, path, iter|
      servers << iter[0]
    end

    @config[:servers] = servers
  end

  def on_connect_button_clicked()
    @connect_dlg.show
    @connectdlg_btn.grab_focus
  end
  alias :on_connect_activate :on_connect_button_clicked

  def on_disconnect_button_clicked()
    disconnect()
  end
  alias :on_disconnect_activate :on_disconnect_button_clicked

  def on_connect_dialog_delete_event(dialog, event)
    dialog.hide_on_delete
  end
  
  def on_connectdlg_server_entry_changed()
    text = @connectdlg_entry.active_text
    @connectdlg_type.active = text[/druby/i] ? 0 : 1
    @connectdlg_btn.sensitive = text.size > 0
  end

  def on_connectdlg_server_entry_key_press_event(server_entry, event)
    case event.keyval
      when Gdk::Keyval::GDK_Return then
        on_connectdlg_button_clicked()
      else
        return false
    end

    return true
  end

  def on_connectdlg_button_clicked()
    text = @connectdlg_entry.active_text
    @connect_dlg.hide

    type_text = @connectdlg_type.active_text

    con_type = case type_text
      when "ruby-breakpoint" then Connection::Breakpoint
      when "ruby-debug" then Connection::RubyDebug
    end

    unless text[/:\d/]
      text += ":%d" % case type_text
        when "ruby-breakpoint" then "wtf".to_i(36) # >:)
        when "ruby-debug" then 8989
      end
    end

    connect_to(text, con_type)
  end

  def connect_to(server, con_type)
    @connection_status.text = @connect_text = "Connecting to %s..." % server

    @connect_thread = Thread.new do
      begin
        @connection = con_type.new
        @connection.on_session = method(:on_session)
        @connection.on_disconnect = method(:on_disconnect)
        @connection.connect(server)
      rescue Exception => error
        on_failure(error)
        sleep 2
        retry
      end
    end

    update_connect_buttons()
  end

  def update_connect_buttons()
    @connect_btn.sensitive = @connect_menuitem.sensitive = !@connection
    @disconnect_btn.sensitive = @disconnect_menuitem.sensitive = @connection
  end

  def update_session_buttons()
    has_page = current_page()
    @continue_btn.sensitive = has_page

    stepping = @connection.stepping_support?() if @connection
    @step_into_btn.sensitive = @step_over_btn.sensitive = stepping && has_page
  end

  def disconnect()
    connection = @connection
    on_disconnect()

    Thread.new do
      connection.disconnect unless connection.nil?

      unless @connect_thread.nil?
        @connect_thread.kill
        @connect_thread = nil
      end
    end
  end

  def current_page()
    active_page = @notebook.get_nth_page(@notebook.page)
    title = @notebook.get_tab_label_text(active_page)
    @pages[title]
  end

  def on_session(session)
    @notebook.remove_page(0) # Remove connect page
    @notebook.show_tabs = true
    @pages[session.title] = Page.new(self, session)
    update_session_buttons()
  end

  def on_disconnect()
    @connection = nil
    update_connect_buttons()
    update_session_buttons()

    @notebook.show_tabs = false
    # Remove pages (session and connection)
    # TODO: Only remove connection
    @notebook.remove_page(0) until @notebook.n_pages == 0

    @connection_status.text = @not_connected
    @notebook.append_page(@connect_page)
  end

  def on_failure(error)
    puts error, error.backtrace

    @connection_status.text = [
      @connect_text,
      "Failed: %s" % error,
      "Will reconnect..."
    ].join("\n\n")
  end

  def on_continue_button_clicked(btn)
    btn.sensitive = false if current_page().continue().nil?
  end

  def on_step_into_button_clicked(btn)
    btn.sensitive = false if current_page().step_into().nil?
  end

  def on_step_over_button_clicked(btn)
    btn.sensitive = false if current_page().step_over().nil?
  end
end
