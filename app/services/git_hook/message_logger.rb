module GitHook
  class MessageLogger
    attr_reader :messages, :wrapped_logger

    def initialize(wrapped_logger = nil)
      @messages = []
      @wrapped_logger = wrapped_logger
    end

    def debug(message = yield)
      add_message(:debug, message)
    end

    def error(message = yield)
      add_message(:error, message)
    end

    def fatal(message = yield)
      add_message(:fatal, message)
    end

    def info(message = yield)
      add_message(:info, message)
    end

    def warn(message = yield)
      add_message(:warn, message)
    end

    private

    def add_message(level, message)
      if wrapped_logger
        wrapped_logger.send(level, message)
      end

      @messages << {
        :level => level.to_s,
        :message => message
      }
    end
  end
end
