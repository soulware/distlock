module Distlock
  module ZK
  	class AffinityPool
      def initialize(options={})
        defaults = {:host => "localhost:2181", :timeout => 10, :root_path => "/affinity/global/test"}
        @options = defaults.merge(options)
      end

      def zk
        @zk ||= begin
          zk = Zookeeper.new(@options[:host], @options[:timeout])

          # todo - initialize the root_path hierarchy here
          zk.stat(:path => @options[:root_path])
        end
      end
    end
  end
end
