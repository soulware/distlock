require 'distlock/version'
require 'distlock/zk/zk'

module Distlock
end

# convenience so we can use either name
module DistLock
  include Distlock
end