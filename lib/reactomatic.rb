require "thread"

require "nio"
require "byebug" rescue nil

require "reactomatic/version"
require "reactomatic/exceptions"
require "reactomatic/buffer"
require "reactomatic/reactor"
require "reactomatic/tcp_server"
require "reactomatic/tcp_connection"

module Reactomatic
  @lock = Monitor.new

  class << self
    attr_accessor :lock
  end

  def self.reactor
    Reactomatic.lock.synchronize do
      unless @reactor
        @reactor = Reactor.new
        @reactor.start
      end

      return @reactor
    end
  end
end