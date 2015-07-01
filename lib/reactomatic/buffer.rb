module Reactomatic
  class Buffer
    attr_reader :max_length

    def initialize(opts = {})
      @max_length = opts[:max_length]
      @opts = opts
      @lock = Mutex.new
      @buffer = ""
    end

    def append(data)
      if @max_length.nil? || length + data.bytesize <= @max_length
        @buffer.concat(data)
      else
        raise BufferFull
      end
    end

    def read
      return @buffer
    end

    def consume(length)
      return @buffer.slice!(0...length)
    end

    def length
      return @buffer.bytesize
    end

    def full?
      return false if @max_length.nil?
      return @buffer.bytesize >= @max_length
    end

    def empty?
      return @buffer.empty?
    end
  end
end