require 'distlock/version'
require 'distlock/lock_error'
require 'distlock/zk/zk'

module Distlock
end

# convenience so we can use either Distlock or DistLock
module DistLock
  include Distlock
end