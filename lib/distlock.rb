require 'logger'
require 'distlock/version'
require 'distlock/lock_error'
require 'distlock/zk/zk'

module Distlock
  def Distlock.logger
    @logger ||= Logger.new(STDOUT)
  end

  def Distlock.logger=(logger)
    @logger = logger
  end

  # factory method for creating instances of lock managers
  def Distlock.new_instance(lock_type = :zk_exclusive_lock, options={})
    locker = Distlock::ZK::ExclusiveLock.new(options)
    locker.logger = Distlock.logger
    locker
  end
end

# convenience so we can use either Distlock or DistLock
module DistLock
  include Distlock
end
