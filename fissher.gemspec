Gem::Specification.new do |s|
  s.name        = 'fissher'
  s.version     = '1.0.3'
  s.date        = '2013-08-02'
  s.summary     = "Fissher"
  s.description = "A utility written to perform batch commands on many servers over SSH. Supports jump servers and hostgroups via a JSON config file."
  s.authors     = ["Jeff Hagadorn"]
  s.email       = 'jeff@aletheia.io'
  s.files       = ["lib/fissher_conf.rb", "lib/fissher_base.rb", "etc/fissher.conf.sample", "README.rdoc" ]
  s.executables	= [ "fissher" ]
  s.homepage    =
    'http://github.com/dahui/fissher'

  # Deps
  s.add_runtime_dependency "net-ssh-multi"
  s.add_runtime_dependency "getopt"
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "highline"
end
