# This is all very complex because we can only send and receive strings via the
# network. (ruby-breakpoint can return DRbObject proxies which we could in
# theory work on directly, but that is not true for ruby-debug.)
class RuDebug::Page
  def initialize_browser()
    @browser_treeview = @glade["browser-treeview"]
    @object_view = @glade["object-view"]
    @object_buf = @object_view.buffer

    @view_to_shell = @glade["view-to-shell-btn"]

    @browser_store = Gtk::TreeStore.new(String, String, Integer, String, TrueClass)
    @browser_treeview.model = @browser_store
    @browser_treeview.rules_hint = true
    renderer = Gtk::CellRendererText.new

    create_default_tag(@object_buf, 10)

    col = Gtk::TreeViewColumn.new("Attribute", renderer, :text => 0)
    col.sizing = Gtk::TreeViewColumn::FIXED
    col.reorderable = false
    col.expand = true
    col.resizable = true
    @browser_treeview.append_column(col)
    renderer = Gtk::CellRendererText.new()
    renderer.size_points = 8
    renderer.ellipsize = Pango::ELLIPSIZE_MIDDLE
    col = Gtk::TreeViewColumn.new("Value", renderer, :text => 1)
    col.sizing = Gtk::TreeViewColumn::FIXED
    col.reorderable = false
    col.expand = true
    col.resizable = true
    @browser_treeview.append_column(col)
    renderer = Gtk::CellRendererText.new      
    col = Gtk::TreeViewColumn.new("OID", nil, :text => 2)
    col.visible = false
    @browser_treeview.append_column(col)
    renderer = Gtk::CellRendererText.new      
    col = Gtk::TreeViewColumn.new("Class", renderer, :text => 3)
    col.visible = false
    @browser_treeview.append_column(col)
    renderer = Gtk::CellRendererText.new      
    col = Gtk::TreeViewColumn.new("Virtual", renderer, :text => 4)
    col.visible = false
    @browser_treeview.append_column(col)

    @browser_treeview.headers_visible = true
    @browser_treeview.headers_clickable = false
    @browser_treeview.enable_search = false
  end

  def load_browser()
    load_data(@browser_treeview)
  end

  def attribute_for(iter) # Attribute description
    iter[0]
  end

  def value_for(iter) # Value string
    iter[1]
  end
  
  def oid_for(iter) # Object id
    iter[2]
  end

  def class_for(iter) # Class string
    iter[3]
  end

  # Virtual attributes are attributes that don't really exist that way.
  # They are just information we poll for the user and should not get
  # information like classes and so on.
  def is_virtual?(iter) # Virtual attribute?
    iter[4]
  end
  
  def on_browser_treeview_cursor_changed(treeview)
    path, column = *treeview.cursor # We don't care about selected column
    iter = treeview.model.get_iter(path)
    text = [
      value_for(iter),
      #class_for(iter)
    ].join("\n\n")
    
    @object_buf.text = ""
    highlight_inspect(text, @object_buf)

    @session.eval("$rudebug.selected = %s" % pid_to_obj(oid_for(iter)))
    @view_to_shell.sensitive = true
  end

  def on_view_to_shell_btn_clicked(button)
    @shell_in.delete_selection
    @shell_in.insert_at_cursor("$rudebug.selected")
    @shell_in.grab_focus
    sel_start, sel_end = *@shell_in.selection_bounds
    @shell_in.select_region(sel_end, sel_end)
  end

  def root_code()
    "[['context', false, #{eval_data("binding")}]]"
  end

  def dummy_attribute()
    "DUMMY"
  end
  
  def on_browser_treeview_row_expanded(treeview, iter, path)
    load_data(treeview, iter)
  end

  def pid_to_obj(pid)
    "ObjectSpace._id2ref(%s)" % pid
  end

  # TODO: Refresh functionality?

  def load_data(treeview, parent_iter = nil)
    store = treeview.model
    code = nil

    if parent_iter.nil? then
      treeview.model.clear
      code = root_code() % []
    else
      dummy = parent_iter.first_child
      if attribute_for(dummy) == dummy_attribute() then  
        # Remove dummy
        store.remove(parent_iter.first_child)

        parent_class = class_for(parent_iter)
        pid = oid_for(parent_iter)
  
        code_template = attributes_for(parent_class, is_virtual?(parent_iter))
        code = code_template % pid_to_obj(pid)
      end
    end

    if code then
      attributes = eval(@session.eval(code))
      attributes.each do |(attribute, virtual, value, klass, oid)|
        iter = store.append(parent_iter)
        iter[0], iter[1], iter[2], iter[3], iter[4] =
        attribute, value, oid, klass, virtual
  
        if can_expand?(iter, klass, oid) then
          dummy_iter = store.append(iter)
          dummy_iter[0] = dummy_attribute()
        end
      end

      if parent_iter then
        treeview.collapse_row(parent_iter.path)
        treeview.expand_row(parent_iter.path, false)
      end
    end
  end

  def eval_data(code, needs_ref = false)
    ref = needs_ref ? "$rudebug.add_ref(#{code})" : code
    "$rudebug.inspect_obj((#{code})), (#{code}).class.to_s, (#{ref}).object_id"
  end

  def attributes_for(klass, virtual)
    code_parts = []

    hash_code = 

    code_parts << if !virtual then %<
      (%1$s.methods(false).empty?() ? [] : [
        [ "eigenclass", false,
          #{eval_data("class << %1$s; self; end")} ]]
      ) +

      (%1$s.is_a?(Module) ? [] : [
        [ "class", false,
          #{eval_data("%1$s.class")} ]]
      ) +

      (%1$s.instance_variables.empty?() ? [] : [
        [ "ivars", true,
          #{eval_data(%<
            $rudebug.to_pairs(%1$s.instance_variables.sort) do |rudebug_ivar|
              %1$s.instance_variable_get(rudebug_ivar)
            end>, true)
          }]
      ]) +

      (!%1$s.respond_to?(:size) ? [] : [
        [ "size", true,
          #{eval_data("%1$s.size rescue 'error'")} ]]
      )>
    end

    code_parts << if klass == "Binding" or klass == "Proc" then %<[
      [ "location", true,
        #{eval_data("eval('[__FILE__, __LINE__]', %1$s).join(':')", true)} ],
      [ "self", false,
        #{eval_data("eval('self', %1$s)")} ],
      [ "lvars", true,
        #{eval_data(%<
          $rudebug.to_pairs(
            (eval('local_variables', %1$s) +
              (eval('$~.nil?', %1$s) ? [] : ['$~']) +
              (eval('$_.nil?', %1$s) ? [] : ['$_']) -
              ['_', 'bp', 'client']
            ).sort
          ) do |rudebug_lvar|
            eval(rudebug_lvar, %1$s)
          end>, true)
        }],
      [ "caller", true,
        #{eval_data(%<$rudebug.to_list(eval('caller', %1$s))>, true)}
      ]]>
    elsif klass == "Array" then %<
      (0 .. %1$s.size - 1).map do |rudebug_idx|
        [ rudebug_idx.inspect, false,
          #{eval_data("%1$s[rudebug_idx]")} ]
      end>
    elsif klass == "Hash" then %<
      %1$s.map do |rudebug_key, rudebug_val|
        [ rudebug_key.inspect, false,
          #{eval_data("rudebug_val")} ]
      end>
    elsif klass == "$rudebug::Pairs" then %<
      %1$s.map do |rudebug_key, rudebug_val|
        [ rudebug_key.to_s, true,
          #{eval_data("rudebug_val")} ]
      end>
    elsif klass == "Class" then %<
      (%1$s == Object ? [] : [
        [ "superclass", true,
          #{eval_data("%1$s.superclass")} ]]
      )>
    elsif klass == "Object" then %<
      (%1$s != ENV ? [] : 
        %1$s.map do |rudebug_key, rudebug_val|
          [ rudebug_key.inspect, true,
          #{eval_data("rudebug_val", true)} ]
        end
      )>
    end

    code_parts << if klass == "Class" or klass == "Module" then %<[
      [ "modules", true,
        #{eval_data("%1$s.included_modules", true)} ],
      [ "constants", true,
        #{eval_data(%<
          $rudebug.to_pairs(%1$s.constants.sort) do |rudebug_const|
            %1$s.const_get(rudebug_const)
          end>, true)
        }],
      [ "imethods", true,
        #{eval_data(%<
          $rudebug.to_pairs(%1$s.instance_methods(false).sort) do |rudebug_imethod|
            %1$s.instance_method(rudebug_imethod)
          end>, true)
        }]]>
    end

    code_parts.compact.map { |part| part.strip }.join(" + ")
  end

  def can_expand?(iter, klass, pid)
    # No cyclic nodes
    return false if is_cyclic?(iter)
    code_template = attributes_for(klass, is_virtual?(iter))
    # Short-circuit empty attributes (optimization)
    return false if code_template == ""
    #puts "template: %s" % code_template
    code = code_template % pid_to_obj(pid)
    #puts "code: %s" % code
    result = @session.eval(code)
    #p result
    #p [code, result]
    attributes = eval(result)
    !attributes.empty?
  end

  def is_cyclic?(iter)
    value = value_for(iter)

    while iter = iter.parent
      return true if value_for(iter) == value
    end

    return false
  end
end
