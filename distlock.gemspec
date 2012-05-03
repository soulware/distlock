# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "distlock/version"

Gem::Specification.new do |s|
  s.name        = "distlock"
  s.version     = Distlock::VERSION
  s.authors     = ["Simon Horne"]
  s.email       = ["simon@soulware.co.uk"]
  s.homepage    = "http://soulware.github.com/distlock"
  s.summary     = %q{Distributed Locking}
  s.description = %q{Distributed Locking}

  s.rubyforge_project = "distlock"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:

  s.add_development_dependency "rake", "~> 0.9"
  s.add_development_dependency "rspec", "~> 2.0"

  # todo remove these
  # s.add_development_dependency "zookeeper", "~> 0.4"
  # s.add_development_dependency "redis"
  # s.add_development_dependency "system_timer"
end
