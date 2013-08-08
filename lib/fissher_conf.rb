
#############################################
#  Option/config parsing for Fissher        #
#############################################

require 'json'
require 'highline/import'
require 'getopt/std'

# Module for all aspects of configuration within fissher.
module FissherConf
  
  # Misc methods for doing dirty work within the app.
  class Misc
    
    # A wrapper function used to request the password from stdin.
    #
    # @param prompt [String] The banner displayed to the user.
    # @return [String] The password, as entered by the user.
    def getpass(prompt="Enter remote password: ")
      ask(prompt) {|q| q.echo = false}
    end

    # Method for returning hosts from hostgroup.
    #
    # @param grp [String] The hostgroup, contained within the config.
    # @param conf [Hash] The parsed configuration file
    # @param conf_file [String] The configuration file, with path.
    # @return [Array] An array of the hosts contained in the hostgroup within the config file.
    def group_hosts( grp,conf,conf_file )
      if conf[:hostgroups][:"#{grp}"] 
        conf[:hostgroups][:"#{grp}"][:hosts]
      else
        abort "Fatal: hostgroup #{grp} not defined in #{conf_file}!\n"
      end
    end
  end

  # Print usage message
  def usage
    app = File.basename($0)
    puts "#{app} [flags] [command]:\n"
    puts "-G Hostgroup       Execute command on all hosts listed in the JSON config for \n"
    puts "                   the specified group.\n"
    puts "-H Host1,Host2     Execute command on hosts listed on the command line\n"
    puts "-g jumpbox         Manually specify/override a jump server, if necessary.\n"
    puts "-s 		   Execute the provided commands with sudo."
    puts "-u username        Manually specify/override username to connect with.\n"
    puts "-p                 Use password based authentication, specified via STDIN\n"
    puts "-c config.json     Manually specify the path to your fissher config file\n"
    puts "-n num             Number of concurrent connections. Enter 0 for unlimited.\n"
    puts "-U username	   Specify an alternate user in conjunction with -s\n" 
    puts "                   (E.G. -U webmaster)\n"
  end

  # A shortcut method to make errors a little more graceful.
  #
  # @param msg [String] the message to be displayed before the usage message.
  def die( msg )
    puts "#{msg}\n"
    usage
    exit 1
  end

  # Parse command line options using getopt and options within the json config file.
  def handle_opts
    opt = Getopt::Std.getopts("pc:g:G:u:n:sH:hU:")
    ret = Hash.new

    if opt["h"]
      usage
      exit 1
    end
 
    # Import configuration, either from default or a custom JSON config
    if opt["c"]
      conf_file = opt["c"]
    elsif File.exists?("#{Dir.home}/.fissherrc")
      conf_file = "#{Dir.home}/.fissherrc"
    elsif File.exists?("/etc/fissher/fissher.conf")
      conf_file = "/etc/fissher/fissher.conf"
    else
      conf_file = File.dirname(__FILE__)  + "/../etc/fissher.conf"
    end
    
    # Ensure the file exists
    begin 
      config = JSON.parse(File.read(conf_file),:symbolize_names => true)
    rescue

      etcloc = File.dirname(__FILE__).to_s.gsub(/\/lib$/, '/etc')
      puts <<EOB
  ****    It appears that you have not yet created your config file!    ****
  You can do this by copying the sample config to one of the following
  locations:

  ~/.fissherrc
  /etc/fissher/fissher.conf
  #{etcloc}/fissher.conf

  You can find a copy of the sample in the following location:

  #{etcloc}

  A script will be included in the next release that will generate the file
  for you if it does not already exist.
EOB
      abort
    end
    
    # Use sudo for our command
    if opt["s"]
      if opt["U"]
        sudo_cmd = "sudo -u #{opt['U']}"
      else
        sudo_cmd = "sudo"
      end
    end

    # Gateway if an edgeserver is present
    if opt["g"]
      ret[:gateway] = opt["g"]
    elsif opt["G"] && !config[:hostgroups][:"#{opt['G']}"][:gateway].nil?
      ret[:gateway] = config[:hostgroups][:"#{opt['G']}"][:gateway]
    elsif !config[:default_gateway].nil?
      ret[:gateway] = config[:default_gateway]
    end  

    # Hostgroup used for batch jobs
    if opt["G"]
      abort "You may only specify one of -G or -H!\n" unless opt["H"].nil?
      h = Misc.new
      ret[:hostlist] = h.group_hosts(opt["G"],config,conf_file) 
    end

    # Username used by connections
    if opt["u"]
      ret[:user] = opt['u']
    elsif config[:user]
      ret[:user] = config[:user]
    end
  
    # Job Concurrency limit
    if opt["n"] == '0'
      ret[:concurrency] = nil
    elsif opt["n"]
      ret[:concurrency] = opt["n"].to_i
    elsif config[:concurrency]
      ret[:concurrency] = config[:concurrency].to_i
    else
      ret[:concurrency] = 10
    end

    # Host list
    if opt["H"]
      abort "You may only specify one of -G or -H!\n" unless opt["G"].nil?
      if opt["H"] =~ /,/
        ret[:hostlist] = opt["H"].split(",")
      else
        ret[:hostlist] = [ opt["H"] ]
      end
    end

    # Get our account password
    if (opt["p"] || config[:enable_password] == 'true')
      p = Misc.new
      ret[:password] = p.getpass()
    else
      ret[:password] = nil
    end
    
    # Our command
    if ARGV.count >= 1
      if sudo_cmd
        ret[:command] = "#{sudo_cmd} " + ARGV.join(' ').to_s
      else
        ret[:command] = ARGV.join(' ').to_s 
      end
    else
      die "No command specified!\n" unless !ret[:command].nil?
    end
    ret
  end
end

