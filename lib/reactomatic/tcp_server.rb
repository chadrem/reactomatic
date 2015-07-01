module Reactomatic
  class TcpServer
    attr_accessor :reactor

    def initialize(opts = {})
      @opts = opts
      @reactor = opts[:reactor] || Reactomatic.reactor
    end

    def listen(host, port, klass)
      raise AlreadyStarted if @server

      @host = host
      @port = port
      @klass = klass

      @socket = TCPServer.new(@host, @port)
      @reactor.register(@socket, :r, method(:__selected__))

      nil
    end

    def close
      if @socket
        @reactor.deregister(@socket)
        @socket.close
        @socket = nil
      end

      nil
    end

    private

    #
    # Internal methods (don't use).
    #

    def __selected__(monitor)
      if monitor.closed?
        @reactor.deregister(@server)
        return
      end

      if monitor.readable?
        @klass.new({:reactor => @reactor, :socket => monitor.io.accept_nonblock})
      end
    end
  end
end