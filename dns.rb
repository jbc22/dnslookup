#!/usr/bin/env ruby

# Written by J. Brett Cunningham (@jbc22)
# EventMachine code reused from Postrank
# http://developer-in-test.blogspot.com/2010/01/dns-lookup-in-ruby-blocking-and.html

require "rubygems"
require "resolv"
require "eventmachine"
require "csv"
require "optparse"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: dnslookup.rb [options]"
  opts.on("-v", "--verbose", "Turn on verbosity") do |v|
    options[:verbose] = v
  end
  opts.on("-f", "--file", "Input csv file containing domains") do |f|
    options[:file] = f
  end
end.parse!

class Dns
  include EM::Deferrable
  def resolve_hostname(hostname)
    begin
      ip = Resolv.getaddress(hostname)
      set_deferred_status :succeeded, ip
    rescue Exception => ex
      set_deferred_status :failed, ex.to_s
    end
  end
end

start = Time.now
EventMachine.run {
  CSV.open(@@filepath, 'r', ',') do |row|
      domain = row[0]
      p "Requesting DNS info for #{domain}" if :verbose 
      dns0 = Dns.new
      dns0.callback {|response| p "For #{domain} #{response}" if :verbose}
      dns0.errback {|response| p "For #{domain} #{response}" if :verbose}
      Thread.new { dns0.resolve_hostname domain}
   end

    EM.stop
}
finish = Time.now

p "Time take for querying #{finish - start} seconds" if :verbose 
