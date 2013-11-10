#!/usr/bin/env ruby
#
# Queries fixed bugs from the git changelog and compares it with the
# current Bugzilla bugs.
#
require 'rubygems'
require 'yaml'


module GitChangeLog

  def self.get_fixed_bugs
    %x(#{log_for_bugs_query}).gsub!('Bug: ', '').split.join(',')
  end

  def self.log_for_bugs_query
    "git log --no-merges --since='1 month ago' --grep='^Bug:' --pretty=%b | grep Bug:"
  end

end


configfile = "#{ENV['HOME']}/.bugquery.yaml"
if File.exist? configfile
  config = YAML.load_file(configfile)
  bug_status = config['bug_status']
  product = config['product']
  flags = config['flag']
  format = config['format']
else
  puts <<-eos
  Need a configfile: #{configfile}
  Contents should look like:

  ---
  bug_status: ASSIGNED
  product: <BUGZILLA PRODUCT>
  flag: <flag to query on>
  format: %{bug_id}: %{short_desc}
  eos
  exit
end

query = "bugzilla query -t '#{bug_status}' -p '#{product}' --flag=#{flags} --bug_id=#{GitChangeLog.get_fixed_bugs} --outputformat='#{format}'"
system "bugzilla login" unless File.exist?("#{ENV['HOME']}/.bugzillacookies")
puts query
bugs_to_change = `#{query}`

if bugs_to_change.any?
  puts "Bugs to consider:\n#{bugs_to_change}"
else
  puts "No fixed bugs in status: #{bug_status}"
end
