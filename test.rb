#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require "./rosumi.rb"

$options = { }
$options[:verbose] = false
@parser = OptionParser.new do |opts|

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    $options[:verbose] = true
  end

  opts.on('-u', "--username USERNAME", "iCloud Username") do |v|
    $options[:username] = v
  end

  opts.on('-p', "--password PASSWORD", "iCloud Password") do |v|
    $options[:password] = v
  end

end

begin
  @options = @parser.parse!(ARGV)
  mandatory = [:username, :password]
  missing   = mandatory.select { |param| $options[param].nil? }
  if not missing.empty?
    descr = missing.map { |o| "--#{o}" }
    puts "Missing options: #{descr.join(', ')}"
    puts @parser
    exit 1
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts @parser
  exit
end

r = Rosumi.new($options[:username], $options[:password], $options[:verbose])
#=> #<Rosumi:0x0000010083b048 @user="username", @pass="password", @devices=[], @http=#<Net::HTTP fmipmobile.me.com:443 open=false> 

puts r.locate
#=> {:name=>"Steve’s iPhone", :latitude=>23.5423458632445456, :longitude=>23.923433562234181818, :accuracy=>80.0, :timestamp=>1279839672446, :position_type=>"Wifi"} 

#####
# EOF
