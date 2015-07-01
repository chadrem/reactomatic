module Reactomatic
  class ReactomaticError < RuntimeError; end
  class AlreadyStarted < ReactomaticError; end
  class MustOverrideMethodError < RuntimeError; end
  class BufferFull < RuntimeError; end
end