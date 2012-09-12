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
  options[:file] = "domains.csv"
  opts.on("-f", "--file FILE", "Input csv file containing domains, default domains.csv") do |f|
    options[:file] = f
  end
  options[:nameserver] = '8.8.8.8'
  opts.on("-n","--nameserver nameserver", "DNS Server to use, default 8.8.8.8") do |n|
    options[:nameserver] = n
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

loop do
  start = Time.now
  EventMachine.run {
    CSV.open(options[:file], 'r', ',') do |row|
        domain = row[0]
        p "Requesting DNS info for #{domain}" if options[:verbose ]
        dns0 = Dns.new
        dns0.callback {|response| p "For #{domain} #{response}" if options[:verbose]}
        dns0.errback {|response| p "For #{domain} #{response}" if options[:verbose]}
        Thread.new { dns0.resolve_hostname domain}
     end

      EM.stop
  }
  finish = Time.now

  p "Time take for querying #{finish - start} seconds" if options[:verbose]

  sleep(3600)
end
