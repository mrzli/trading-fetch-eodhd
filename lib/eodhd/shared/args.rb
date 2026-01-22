# frozen_string_literal: true

module Eodhd
  module Args
    class Error < StandardError
      attr_reader :usage

      def initialize(message, usage: nil)
        super(message)
        @usage = usage
      end
    end

    class Help < StandardError
      attr_reader :usage

      def initialize(usage)
        super("help")
        @usage = usage
      end
    end

    module_function

    # Wraps a parse block with exception handling for Help and Error.
    # Returns the result of the block on success, exits on Help/Error.
    def with_exception_handling
      yield
    rescue Help => e
      puts e.usage
      exit 0
    rescue Error => e
      warn e.message
      warn e.usage if e.usage
      exit 2
    end
  end
end
