#!/usr/local/bin/ruby

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'net/ssh/multi'
require 'lib/fissher_conf'
include FissherConf

opts = FissherConf.handle_opts

Net::SSH::Multi.start(:concurrent_connections => opts["concurrency"]) do |session|
  if opts["gateway"]
    session.via opts["gateway"], opts["user"], :password => opts["password"]
  end

  # Create our connection list
  abort "No hosts specified! Please use -H or -G!\n" unless !opts["hostlist"].nil?
  opts["hostlist"].each do |host|
    session.use host, :user => opts["user"], :password => opts["password"]
  end

  # Get a PTY and exec command on servers
  session.open_channel do |ch|
    ch.request_pty do |c, success|
      abort "could not request pty" unless success
      ch.exec opts["command"]
      ch.on_data do |c_, data|
        if data =~ /\[sudo\]/
          ch.send_data(opts["password"] + "\n")
        else
          puts "[#{ch[:host]}]: #{data}" unless data =~ /^\n$|^\s*$/
        end
      end
    end
  end

  # go time
  session.loop
end
