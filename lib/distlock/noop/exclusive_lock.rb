module Distlock
  module Noop
    class ExclusiveLock

      def initialize(options={})
      end
      
      def with_lock(path=nil)
        yield if block_given?
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def logger=(logger)
        @logger = logger
      end      
    end
  end
end
