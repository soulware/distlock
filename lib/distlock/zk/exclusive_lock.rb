module Distlock
  module ZK
  	class ExclusiveLock
      include Distlock::ZK::Common

      WATCHER_TIMEOUT = 60 #seconds

      def initialize(options={})
        defaults = {:host => "localhost:2181", :timeout => 10, :root_path => "/lock/exclusive/default"}
        @options = defaults.merge(options)
      end

      def owner?
        @owner
      end
      
      def my_lock
        @my_lock
      end

      def do_watcher(watcher, lock)
        if watcher.type == ZookeeperConstants::ZOO_DELETED_EVENT
          logger.debug "Distlock::ZK::ExclusiveLock#do_watcher: watcher called for delete of node - #{lock}"
        else
          if watcher.type == ZookeeperConstants::ZOO_CREATED_EVENT
            logger.error "Distlock::ZK::ExclusiveLock#do_watcher: watcher called for creation of node (should never happen for an ephemeral node?) - #{lock}"
          elsif watcher.type == ZookeeperConstants::ZOO_SESSION_EVENT
            logger.error "Distlock::ZK::ExclusiveLock#do_watcher: watcher called for zoo session event, closing the session for this client - #{lock}"
          else
            logger.error "Distlock::ZK::ExclusiveLock#do_watcher: watcher called for unexpected event, closing the session for this client - #{lock}, event - #{watcher.type}"
          end

          close
          raise LockError.new("Distlock::ZK::ExclusiveLock#do_watcher: got an unexpected watcher type - #{watcher.type}")
        end

        @watcher_called=true
      end

      def check_for_existing_lock(path)
        children = zk.get_children(:path => path)[:children].sort{|a,b|a.split('-').last <=> b.split('-').last}
        children.detect do |child| 
          logger.debug "checking existing lock for our client_id - #{child} vs. #{zk.client_id}"
          if child.split('-')[1] == "#{zk.client_id}"
            logger.debug "found existing lock for client_id #{zk.client_id}, lock - #{child}, reusing"
            return "#{path}/#{child}"
          end
        end
      end

      def lock(path)
        raise LockError.new("invalid lock path, must start with '/'") unless path.start_with?("/")
        @owner = false
        
        safe_create(path)
        
        # TODO - combine these into a single method like find_or_create
        lock = check_for_existing_lock(path)
        lock = create_sequenced_ephemeral(path) unless lock
        
        logger.debug "my lock path - #{lock}"
        @my_lock = lock
        result = _get_lock(lock)
        logger.info("Distlock::ZK::ExclusiveLock#lock: lock acquired - #{lock}")
        
        result
      end

      def unlock(lock = @my_lock)
        return unless lock

        logger.debug "unlocking - #{lock}"
        
        zk.delete(:path => lock)
        
        if lock == @my_lock
          @my_lock = nil
          @owner = false
        end
      end

      def _get_lock(lock)  
        logger.debug "_get_lock: entered for #{lock}"

        while !@owner

          path = lock.split('/')[0...-1].join('/')
        
          # TODO - pass children in as parameter?
          children = zk.get_children(:path => path)[:children].sort{|a,b|a.split('-').last <=> b.split('-').last}
          
          puts lock
          puts path
          puts children.inspect

          lock_last = lock.split('/').last
          lock_idx = children.index(lock_last)

          if lock_idx.nil?
            logger.error("Distlock::ZK::ExclusiveLock#_get_lock: failed to find our lock in the node children (connection reset?)")
            raise LockError.new("failed to find our lock in the node children (connection reset?)")
          elsif lock_idx == 0  
            logger.debug "lock acquired (client id - #{zk.client_id}), lock - #{lock}"
            @owner = true
            return true
          else
            logger.debug "Distlock::ZK::ExclusiveLock#_get_lock: lock contention for #{lock} - #{children.inspect} (my client id - #{zk.client_id})"
            logger.info "Distlock::ZK::ExclusiveLock#_get_lock: lock contention - #{lock}"

            to_watch = "#{path}/#{children[lock_idx-1]}"
            logger.debug "about to set watch on - #{to_watch}"

            # 2-step process so we minimise the chance of setting watches on the node if it does not exist for any reason
            @watcher_called=false
            @watcher = Zookeeper::WatcherCallback.new { do_watcher(@watcher, lock) }
            resp = zk.stat(:path => to_watch)
            resp = zk.stat(:path => to_watch, :watcher => @watcher) if resp[:stat].exists

            if resp[:stat].exists
              logger.info "Distlock::ZK::ExclusiveLock#_get_lock: watcher set, node exists, watching - #{to_watch}, our lock - #{lock}"
              start_time = Time.now
              while !@watcher_called
                sleep 0.1

                if (start_time + WATCHER_TIMEOUT) < Time.now
                  logger.error("Distlock::ZK::ExclusiveLock#_get_lock: timed out while watching - #{to_watch}, our lock - #{lock}, closing session and bombing out")
                  close
                  raise LockError.new("Distlock::ZK::ExclusiveLock#_get_lock timed out while waiting for watcher")
                end
              end
            else
              logger.error("Distlock::ZK::ExclusiveLock#_get_lock: node we are watching does not exist, closing session, lock - #{lock}")
              close
              raise LockError.new("node we tried to watch does not exist")
            end
          end
        end
      end

      def with_lock(path="/distlock/zk/exclusive_lock/default")                            
        begin
          lock(path)
          yield if block_given?
        rescue ZookeeperExceptions::ZookeeperException::SessionExpired => e
          close
          raise LockError.new("error encountered while attempting to obtain lock - #{e}, zookeeper session has been closed")
        rescue ZookeeperExceptions::ZookeeperException => e
          raise LockError.new("error encountered while attempting to obtain lock - #{e}")
        ensure
          begin
            unlock
          rescue ZookeeperExceptions::ZookeeperException => e
            logger.error("Distlock::ZK::ExclusiveLock#with_lock: error while unlocking - #{e}, closing session to clean up our lock")
            close
          end
        end
      end            
    end
  end
end
