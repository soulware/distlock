module Distlock
  module ZK
  	class AffinityPool
      def initialize(options={})
        defaults = {:host => "localhost:2181", :timeout => 10, :root_path => "/affinity/pool/test"}
        @options = defaults.merge(options)
      end

      def zk
        @zk ||= begin
          zk = Zookeeper.new(@options[:host], @options[:timeout])
        end
      end

      # does a node exist for the given path?
      def exists?(path)
        zk.stat(:path => path)[:stat].exists
      end

      # create all levels of the hierarchy as necessary
      # i.e. for "foo/bar/baz", creates the following nodes - 
      #
      # /foo
      # /foo/bar
      # /foo/bar/baz
      #
      def safe_create(path)
        path_elements = path.split("/")
        
        all = []
        while(!path_elements.empty?)
          all << path_elements
          path_elements = path_elements[0..-2]
        end

        all.reverse.each do |path_elements|
          puts path_elements.inspect
          path = "/" + path_elements.join("/")
          zk.create(:path => path) unless exists?(path)
        end
      end
    end
  end
end
