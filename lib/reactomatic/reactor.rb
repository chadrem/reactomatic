module Reactomatic
  class Reactor
    SELECTOR_TIMEOUT = 0.1 # Seconds.

    def initialize(opts = {})
      @selector = NIO::Selector.new
      @selector_timeout = opts[:selector_timeout] || SELECTOR_TIMEOUT
      @run_lock = Mutex.new
      @next_tick_queue = Queue.new
    end

    def start(opts = {})
      @run_lock.synchronize do
        raise AlreadyStarted if @thread
        @thread = Thread.new do
          begin
            while !@selector.closed?
              process_next_tick_queue
              monitor_io_objects
            end
          rescue Exception => e
            exception_handler(e)
          end
        end
      end
    end

    def stop
      @run_lock.synchronize do
        @selector.close
        @thread.join
      end
    end

    def register(io, interest, target)
      monitor = @selector.register(io, interest)
      monitor.value = target

      nil
    end

    def deregister(io)
      @selector.deregister(io)

      nil
    end

    def registered?(io)
      @selector.registered?(io)
    end

    def next_tick(callback = nil, &block)
      func = callback || block

      @next_tick_queue.push(func)

      nil
    end

    def schedule(callback = nil, &block)
      func = callback || block

      if Thread.current == @thread
        func.call
      else
        next_tick(func)
      end

      nil
    end

    def on_exception(&block)
      @on_exception = block
    end

    def exception_handler(e)
      @on_exception.call(e) if @on_exception
    rescue Exception => e2
      puts "EXCEPTION in exception handler: #{e2.class.name}: #{e2.message}\n#{e2.backtrace.join("\n")}"
    end

    private

    def process_next_tick_queue
      @next_tick_queue.length.times do
        begin
          @next_tick_queue.pop.call
        rescue Exception => e
          exception_handler(e)
        end
      end
    end

    def monitor_io_objects
      @selector.select(SELECTOR_TIMEOUT) do |monitor|
        monitor.value.call(monitor)
      end
    end
  end
end