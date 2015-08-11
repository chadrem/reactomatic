module Reactomatic
  class TcpConnection
    def initialize(opts = {})
      @opts = opts

      @reactor = opts[:reactor] || Reactomatic.reactor
      @socket = opts[:socket]
      @write_buffer = opts[:write_buffer] || Buffer.new
      @read_count = 0
      @write_count = 0
      @read_finished = false
      @write_finished = false
      @lock = Monitor.new
      @no_delay = opts.include?(:no_delay) ? opts[:no_delay] : true

      on_initialize

      if @socket
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if @no_delay
        register
      end
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
        return nil if @socket.nil?

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

      read_interest = !@read_finished
      write_interest = !@write_finished && @write_buffer.any?

      if read_interest && write_interest
        interests = :rw
      elsif read_interest
        interests = :r
      elsif write_interest
        interests = :w
      else
        interests = nil
      end

      if interests
        @reactor.register(@socket, interests, method(:selected))
      else
        close
      end
    end

    def selected(monitor)
      @lock.synchronize do
        begin
          read_nonblock if monitor.readable?
          write_nonblock if monitor.writable?
        rescue Exception => e
          close
          exception_handler(e)
          return
        end

        register
      end
    end

    def read_nonblock
      data = nil
      read_data = false

      begin
        data = @socket.read_nonblock(1024**2)
        read_data = true
      rescue IO::WaitReadable
        return
      rescue Exception
        @read_finished = true
        return
      end

      on_receive_data(data)
      @read_count += data.bytesize
    end

    def write_nonblock
      return if @write_buffer.empty?

      begin
        num_bytes = @socket.write_nonblock(@write_buffer.read)
      rescue IO::WaitWritable
        return
      rescue Exception
        @write_finished = true
        return
      end

      @write_buffer.consume(num_bytes)
      @write_count += num_bytes
      on_sent_data(num_bytes)
    end

    def exception_handler(e)
      reactor.schedule do
        reactor.exception_handler(e)
      end
    end
  end
end