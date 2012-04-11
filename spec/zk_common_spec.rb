require 'distlock/zk/common'

class ZKFoo
  include Distlock::ZK::Common
end

describe Distlock::ZK::Common do
  it "should do something" do
    true
  end
end