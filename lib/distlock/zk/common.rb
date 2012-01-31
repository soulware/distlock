module Distlock
  module ZK
    module Common
      def zk
        @zk ||= begin
          zk = Zookeeper.new(@options[:host], @options[:timeout])
        end
      end

      # does a node exist for the given path?
      def exists?(path)
        puts "checking if #{path} exists"
        result = zk.stat(:path => path)[:stat].exists
        puts result
        result
      end
      
      # create all levels of the hierarchy as necessary
      # i.e. for "/foo/bar/baz", creates the following nodes - 
      #
      # /foo
      # /foo/bar
      # /foo/bar/baz
      #
      def safe_create(path)
        path_elements = path.split("/").reject{ |x| x=="" }
        
        all = []
        while(!path_elements.empty?)
          all << path_elements
          path_elements = path_elements[0..-2]
        end

        all.reverse.each do |path_elements|
          path = "/" + path_elements.join("/")
          zk.create(:path => path) unless exists?(path)
        end
      end

      def create_sequenced_ephemeral(path, prefix="lock")
        lock_path = [path, "#{prefix}-#{zk.client_id}-"].join("/")
        puts lock_path
        result = zk.create(:path => lock_path, :sequence => true, :ephemeral => true)
        puts result
      end            
    end
  end
end