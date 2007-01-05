class Connection
  class RemoteException < Exception
  end

  class Base
    attr_accessor :on_session, :on_disconnect

    Code = <<-END_CODE
      $rudebug = Module.new do
        extend self

        def inspect()
          "$rudebug"
        end
        alias :name :inspect

        attr_accessor :selected

        const_set(:Refs, [])

        def add_ref(ref)
          $rudebug::Refs << ref
          return ref
        end

        const_set(:Pairs, Class.new {
          def self.[](*pairs)
            new(*pairs)
          end

          def self.to_s()
            "$rudebug::Pairs"
          end

          def initialize(*pairs)
            @pairs = pairs
          end

          def inspect()
            "{ %s }" % @pairs.map do |key, value|
              [
                key.is_a?(Numeric) ? key : key.to_sym.inspect,
                $rudebug.inspect_obj(value)
              ].join(" => ")
            end.join(", ")
          end

          def each(&block)
            @pairs.each(&block)
          end

          def size()
            @pairs.size
          end

          include Enumerable
        })

        def to_pairs(items, &block)
          $rudebug::Pairs[*items.map { |item| [item, block.call(item)] }]
        end

        def to_list(items)
          to_pairs(0 .. items.size - 1) { |idx| items[idx] }
        end

        def inspect_obj(obj)
          case obj
            when UnboundMethod, Method then
              inspect_method(obj)
            else
              #require 'pp'
              #PP.pp(obj, "", 30).chomp
              obj.inspect
          end
        end

        def inspect_method(method)
          re = /^\x23<(?:Unbound)?Method: ([^(]+)(?:\\(([^)]+)\\))?\x23(.+?)>$/
          if md = re.match(method.inspect) then
            klass, diff_origin, name = *md.captures
            origin = diff_origin || klass
            argc = method.arity
            more = argc < 0
            argc = -argc if more
  
            old_name = "a"
            args = (1 .. argc).map do |idx|
              arg_name = old_name.dup
              old_name.succ!
              arg_name
            end
            args[-1][0, 0] = "*" if more
            
            "%s\x23%s(%s)" % [origin, name, args.join(", ")]
          else
            method.inspect
          end
        end
      end
    END_CODE

    def self.load_rudebug_code(session)
      session.eval(Code)
    end
  end
end

eval(Connection::Base::Code)
