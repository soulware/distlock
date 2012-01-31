module Distlock
  module ZK
  	class AffinityPool
      include Distlock::ZK::Common

      def initialize(options={})
        defaults = {:host => "localhost:2181", :timeout => 10, :root_path => "/affinity/pool/test"}
        @options = defaults.merge(options)
      end

    end
  end
end
