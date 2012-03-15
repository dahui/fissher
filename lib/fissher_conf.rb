
#############################################
#  Option/config parsing for Fissher        #
#############################################

require 'json'
require 'highline/import'
require 'getopt/std'

module FissherConf
  class Misc
    def getpass(prompt="Enter remote password: ")
      ask(prompt) {|q| q.echo = false}
    end

    # Method for returning hosts from hostgroup.
    def group_hosts( grp,conf,conf_file )
      if conf["hostgroups"]["#{grp}"] 
        conf["hostgroups"]["#{grp}"]["hosts"]
      else
        abort "Fatal: hostgroup #{grp} not defined in #{conf_file}!\n"
      end
    end
  end

  def handle_opts
    opt = Getopt::Std.getopts("pc:C:g:G:u:n:sH:")
    ret = { }
 
    # Import configuration, either from default or a custom JSON config
    if opt["c"]
      conf_file = opt["c"]
    else
      conf_file = File.dirname(__FILE__)  + "/../etc/fissher.json"
    end
    config = JSON.parse(File.read(conf_file))
    
    # Use sudo for our command
    if opt["s"]
      sudo = true
    end

    # Gateway if an edgeserver is present
    if opt["g"]
      ret["gateway"] = opt["g"]
    elsif opt["G"] && config["hostgroups"]["#{opt['G']}"]
      ret["gateway"] = config["hostgroups"]["#{opt['G']}"]["gateway"]
    elsif config['default_gateway']
      ret["gateway"] = config['default_gateway']
    end  

    # Hostgroup used for batch jobs
    if opt["G"]
      abort "You may only specify one of -G or -H!\n" unless opt["H"].nil?
      h = Misc.new
      ret["hostlist"] = h.group_hosts(opt["G"],config,conf_file) 
    end

    # Username used by connections
    if opt["u"]
      ret["user"] = opt['u']
    elsif config['user']
      ret["user"] = config['user']
    end
  
    # Job Concurrency limit
    if opt["n"] == '0'
      ret["concurrency"] = nil
    elsif opt["n"]
      ret["concurrency"] = opt["n"].to_i
    elsif config['concurrency']
      ret["concurrency"] = config['concurrency'].to_i
    else
      ret["concurrency"] = 10
    end

    # Host list
    if opt["H"]
      abort "You may only specify one of -G or -H!\n" unless opt["G"].nil?
      if opt["H"] =~ /,/
        ret["hostlist"] = opt["H"].split(",")
      else
        ret["hostlist"] = [ opt["H"] ]
      end
    end

    # Get our account password
    if opt["p"]
      p = Misc.new
      ret["password"] = p.getpass()
    else
      ret["password"] = nil
    end
    
    if ARGV.count >= 1
      if sudo
        ret["command"] = "sudo " + ARGV.join(' ').to_s
      else
        ret["command"] = ARGV.join(' ').to_s 
      end
    else
      abort "No command specified!\n" unless !ret["command"].nil?
    end
    ret
  end
end

