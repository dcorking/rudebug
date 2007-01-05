require 'rudebug/connection/base'

class Connection::RubyDebug < Connection::Base
  def stepping_support?()
    true
  end

  class Session
    attr_reader :title

    def initialize(connection, location)
      @connection = connection
      @location = location
      @title = location.join(":")
      @done = false

      Connection::Base.load_rudebug_code(self)
    end

    def execute(cmd)
      result = @connection.execute(cmd)
      result ? result.chomp : result
    end

    def eval(code)
      cmd = %(
        p begin;
          [eval(%p, nil, *([
             caller[0].split(":")[0],
             caller[0].split(":")[1].to_i
           ] rescue [])).inspect, nil];
        rescue Exception;
          [nil, $!.inspect];
        end
      ).strip.gsub(/\n\s*/, "")
      result, error = *Kernel.eval(execute(cmd % [code, @location]))

      raise(Connection::RemoteException, error) if error
      return result
    end

    def current_file()
      @location[0]
    end

    def current_line()
      @location[1].to_i
    end

    def source_code(file)
      Kernel.eval(eval("File.read(%p)" % file)).chomp
    end

    def generic_step(cmd)
      result = execute(cmd)

      if result then
        @connection.location?(result)
      else
        @connection.on_disconnect.call()
        @connection.disconnect()
        return nil
      end
    end

    def continue()
      generic_step("cont")
    end

    def step_into()
      generic_step("step")
    end

    def step_over()
      generic_step("next")
    end
  end

  def connect(server)
    require 'ruby-debug'
    require 'socket'
    require 'thread'

    host, port = */^(.+):(\d+)$/.match(server).captures
    port = port.to_i

    @socket = TCPSocket.new(host, port)
    line = @socket.gets
    location = location?(line)

    result = @socket.gets.strip rescue nil
    if !prompt?(result) then
      raise "Not a ruby-debug server"
    end

    @mutex = Mutex.new

    session = Session.new(self, location)
    @on_session.call(session)
  end

  def prompt?(line)
    line[/^PROMPT /] rescue nil
  end

  def location?(line)
    if md = /^(.+?):(\d+): /.match(line) then
      file, line = *md.captures
      [file, line.to_i]
    end
  end

  def execute(cmd)
    @mutex.synchronize do
      @socket.puts(cmd)
      result = @socket.gets
      prompt = @socket.gets

      #p result
      #p [:prompt, prompt]
      return result
    end
  end

  def disconnect()
    begin
      @socket.close
    rescue Exception
    end

    @socket = @mutex = nil
  end
end
