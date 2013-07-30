Gem::Specification.new do |s|
  s.name        = 'fissher'
  s.version     = '1.0.1'
  s.date        = '2013-07-30'
  s.summary     = "Fissher"
  s.description = "A utility written to perform batch commands on many servers over SSH. Supports jump servers and hostgroups via a JSON config file."
  s.authors     = ["Jeff Hagadorn"]
  s.email       = 'jeff@aletheia.io'
  s.files       = ["lib/fissher_conf.rb", "lib/fissher_base.rb"]
  s.executables	= [ "fissher" ]
  s.homepage    =
    'http://rubygems.org/gems/fissher'

  # Deps
  s.add_runtime_dependency "net-ssh-multi"
  s.add_runtime_dependency "getopt"
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "highline"
end
