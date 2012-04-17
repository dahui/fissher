
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'net/ssh/multi'
require 'fissher_conf'
include FissherConf

class FissherBase
  def go_time
    opts = FissherConf.handle_opts unless !opts.nil?

    Net::SSH::Multi.start(:concurrent_connections => opts[:concurrency]) do |session|
      if opts[:gateway]
        session.via opts[:gateway], opts[:user], :password => opts[:password]
      end

      # Create our connection list
      abort "No hosts specified! Please use -H or -G!\n" unless !opts[:hostlist].nil?
      opts[:hostlist].each do |host|
        session.use host, :user => opts[:user], :password => opts[:password]
      end

      if opts[:command] =~ /^sudo/
        if opts[:password].nil?
          p = FissherConf::Misc.new
          opts[:password] = p.getpass
        end

        # Get a PTY and exec command on servers
        session.open_channel do |ch|
          ch.request_pty do |c, success|
            raise "could not request pty" unless success
            ch.exec opts[:command]
            ch.on_data do |c_, data|
              if data =~ /\[sudo\]/
                ch.send_data(opts[:password] + "\n")
              else
                puts "[#{ch[:host]}]: #{data}" unless data =~ /^\n$|^\s*$/
              end
            end
          end
        end
      else
        # Sudo isn't needed. We don't need a PTY.
        session.exec(opts[:command]) 
      end

      # go time... for real.
      session.loop
    end
  end
end
