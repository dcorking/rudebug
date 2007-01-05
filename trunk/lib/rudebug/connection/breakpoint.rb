require 'rudebug/connection/base'

class Connection::Breakpoint < Connection::Base
  def stepping_support?()
    false
  end

  class Session
    attr_reader :title

    def initialize(workspace, title = nil)
      @workspace = workspace
      @title = title
      @done = false

      Connection::Base.load_rudebug_code(self)
    end

    def eval(code)
      @workspace.evaluate(nil, code).inspect
    rescue Exception => e
      raise(Connection::RemoteException, e.inspect)
    end

    def current_file()
      Kernel.eval(eval("bp.file rescue @__bp_file"))
    end

    def current_line()
      Kernel.eval(eval("bp.line rescue @__bp_line")).to_i
    end

    def source_code(file)
      Kernel.eval(eval("File.read(%p)" % file)).chomp
    end

    def continue()
      @done = true
      return nil
    end

    def done?()
      @done
    end

    # Safety
    def step_into() end
    def step_over() end
  end

  def connect(server)
    require 'breakpoint'
    require 'breakpoint/drb'
    require 'drb'

    DRb.start_service()

    @service = DRbObject.new(nil, server)
    @service.eval_handler = method(:eval_handler)
    @service.handler = method(:breakpoint_handler)

    @check_thread = Thread.new(
      @service, @on_disconnect
    ) do |service, on_disconnect|
      loop do
        begin
          service.ping
        rescue DRb::DRbConnError => error
          on_disconnect.call()
          disconnect()
          break
        end

        sleep(0.5)
      end
    end
  end

  def disconnect()
    begin
      @service.handler = nil
      @service.eval_handler = nil
    rescue Exception
    end

    @check_thread.kill if @check_thread
    @check_thread = nil

    DRb.stop_service()
    @service = nil
  end

  def title_filter(message)
    message[/"([^"]+)"/, 1] || message #"
  end

  def breakpoint_handler(workspace, message)
    title = title_filter(message)
    session = Session.new(workspace, title)
    @on_session.call(session)
    sleep 0.1 until session.done?
  end

  def eval_handler(code)
    result = eval(code, TOPLEVEL_BINDING)
    Breakpoint.undumpify(result)
    return result
  end
end
