# This files contains fixes and enhancements to the GTK library

class GladeXML # :nodoc:
  # There's a bug in GladeXML: It tries to guard all elements that were loaded
  # from a glade file against the GC by holding a reference so they won't go
  # away. However, it can try to reference objects which weren't loaded when we
  # supply a root argument. This ought to protect against that case. -- flgr 
  if defined?(guard_source_from_gc) then
    alias :guard_source_from_gc_without_nil_check :guard_source_from_gc
    def guard_source_from_gc(source)
      guard_source_from_gc_without_nil_check(source) unless source.nil?
    end
  end
end

class Gtk::Container # :nodoc:
  include Enumerable
end

class Gtk::ListStore # :nodoc:
  include Enumerable

  def size()
    self.to_a().size()
  end
end