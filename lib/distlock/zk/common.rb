require 'logger'

module Distlock
  module ZK
    module Common
      def zk
        @zk ||= begin
          zk = Zookeeper.new(@options[:host], @options[:timeout])
        end
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def logger=(logger)
        @logger = logger
      end

      # does a node exist for the given path?
      def exists?(path)
        result = zk.stat(:path => path)[:stat].exists
        logger.debug "checking if #{path} exists - #{result}"
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
        logger.debug lock_path
        result = zk.create(:path => lock_path, :sequence => true, :ephemeral => true)
        logger.debug result
        result[:path]
      end 

      # access @zk directly here, we don't want to lazy instantiate again if closed already
      def close
        begin
          @zk.close if @zk
        rescue StandardError, ZookeeperExceptions::ZookeeperException => error
          logger.error("Distlock::ZK::Common#close: caught and squashed error while closing connection - #{error}")
        end

        @zk = nil
      end                 
    end
  end
end