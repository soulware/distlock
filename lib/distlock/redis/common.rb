require 'logger'

module Distlock
  module Redis
    module Common
      def redis
        @redis ||= begin
          redis = ::Redis.new
        end
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
