require 'logger'
require 'distlock/version'
require 'distlock/lock_error'

module Distlock
  def Distlock.logger
    @logger ||= Logger.new(STDOUT)
  end

  def Distlock.logger=(logger)
    @logger = logger
  end

  # factory method for creating instances of lock managers
  def Distlock.new_instance(options={})

    # attempt to require zookeeper blindly
    # if require fails, fallback to redis
    # if fails fall back to noop

    locker=nil

    begin
      require 'distlock/zk/zk'
      locker = Distlock::ZK::ExclusiveLock.new(options)
    rescue LoadError => e
      Distlock.logger.debug "failed to require - #{e}"
      
      begin
        require 'distlock/redis/redis'
        locker = Distlock::Redis::ExclusiveLock.new(options)
      rescue LoadError => e
        Distlock.logger.debug "failed to require - #{e}"

        # noop
        require 'distlock/noop/noop'      
        locker = Distlock::Noop::ExclusiveLock.new(options)
      end
    end

    locker.logger = Distlock.logger
    locker
  end
end

# convenience so we can use either Distlock or DistLock
module DistLock
  include Distlock
end
