module Reactomatic
  class TcpConnection
    def initialize(opts = {})
      @opts = opts

      @reactor = opts[:reactor] || Reactomatic.reactor
      @socket = opts[:socket]
      @write_buffer = opts[:write_buffer] || Buffer.new
      @read_count = 0
      @write_count = 0
      @read_eof = false
      @lock = Monitor.new

      on_initialize
      register if @socket
    end

    #
    # Public methods.
    #

    def reactor
      return @reactor
    end

    def connect(host, port)
      raise 'Not implemented yet.'
    end

    def send_data(data)
      @lock.synchronize do
        @write_buffer.append(data)
        write_nonblock
        register
      end

      nil
    end

    def close
      @lock.synchronize do
        if @socket
          @reactor.deregister(@socket)
          @socket.close
          @socket = nil
          on_disconnect
        end
      end

      nil
    end

    private

    #
    # Event handlers (override these in your subclasses).
    #

    def on_initialize
      puts "initialized!"
    end

    def on_connect
      puts "connected!"
    end

    def on_receive_data(data)
      puts "received #{data.bytesize} bytes of data and echoing back!"
      send_data(data)
    end

    def on_sent_data(num_bytes)
      puts "sent #{num_bytes} of data!"
    end

    def on_disconnect
      puts "disconnected! read bytes: #{@read_count}, wrote bytes: #{@write_count}"
    end

    #
    # Internal methods (don't use).
    #

    def register
      @reactor.deregister(@socket)

      if !@write_buffer.empty? && !@read_eof
        interest = :rw
      elsif @write_buffer.empty? && !@read_eof
        interest = :r
      elsif !@write_buffer.empty?
        interest = :w
      elsif @read_eof
        close
        return
      end

      @reactor.register(@socket, interest, method(:selected))
    end

    def selected(monitor)
      @lock.synchronize do
        read_nonblock if monitor.readable?
        write_nonblock if monitor.writable?
        register
      end
    end

    def read_nonblock
      begin
        data = @socket.read_nonblock(1024**2)
        on_receive_data(data)
        @read_count += data.bytesize
      rescue EOFError
        @read_eof = true
      rescue IO::WaitReadable
      end
    end

    def write_nonblock
      return if @write_buffer.empty?

      begin
        num_bytes = @socket.write_nonblock(@write_buffer.read)
        @write_buffer.consume(num_bytes)
        @write_count += num_bytes
        on_sent_data(num_bytes)
      rescue IO::WaitWritable
      end
    end
  end
end