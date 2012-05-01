module Distlock
  module Redis
    
    #
    # see here for retry count based example - 
    # https://github.com/PatrickTulskie/redis-lock/blob/master/lib/redis/lock.rb
    #
    class ExclusiveLock
      include Distlock::Redis::Common
 
      DEFAULT_LEASE_FOR = 300 # 5 mins
      DEFAULT_RETRY_FOR = 60 # 1 min
      DEFAULT_RETRY_IN = 1 # 1 sec

      def my_lock
        @my_lock
      end

     def lock(path, lease_for = DEFAULT_LEASE_FOR, retry_for = DEFAULT_RETRY_FOR)
        now = Time.now
        retry_until = now + retry_for

        @my_lock = path

        lock_value = generate_lock_value(lease_for)

        while Time.now < retry_until
          if redis.setnx(path, lock_value)
            logger.debug "acquired lock (setnx) - #{my_lock}, #{lock_value}"
            return true
          end

          current_lock = redis.get(my_lock)
          if (current_lock.to_s.split('-').first.to_i) < Time.now.to_i
            updated_lock = redis.getset(my_lock, lock_value)
            if updated_lock == current_lock
              logger.debug "acquired lock (getset) - #{my_lock}, #{lock_value}"
              return true
            end
          end

          sleep DEFAULT_RETRY_IN
        end

        raise LockError.new("failed to get the lock")
      end

      def unlock
        lock_value = redis.get(my_lock)
        unless lock_value
          logger.debug "no lock to release"
          return true
        end

        lease_expires, owner = lock_value.split('-')
        if (lease_expires.to_i > Time.now.to_i) && (owner.to_i == Process.pid)
          redis.del(my_lock)
          logger.debug "released lock - #{my_lock}, #{lock_value}"
          return true
        end
      end

      def generate_lock_value(lease_for=DEFAULT_LEASE_FOR, id=Process.pid)
        "#{Time.now.to_i + lease_for + 1}-#{id}"
      end

      def with_lock(path='/distlock/redis/exclusive_lock/default', lease_for=DEFAULT_LEASE_FOR, retry_for=DEFAULT_RETRY_FOR)
        begin
          lock(path, lease_for, retry_for)
          yield if block_given?
        ensure
          # TODO - store lock path so we don't need to pass it here
          # unlock(path)
          unlock
        end
      end
    end
  end
end
