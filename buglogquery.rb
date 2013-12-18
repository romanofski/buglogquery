#!/usr/bin/env ruby
#
# Queries fixed bugs from the git changelog and compares it with the
# current Bugzilla bugs.
#
require 'rubygems'
require 'yaml'
require 'open3'
require 'logger'


module GitChangeLog

  def self.get_fixed_bugs
    %x(#{log_for_bugs_query}).gsub!('Bug:', '').split.join(',')
  end

  def self.log_for_bugs_query
    "git log --no-merges --since='1 month ago' --grep='^Bug:' --pretty=%b | grep Bug:"
  end

end

class BugzillaQuery

  def initialize(config)
    @bug_status = config['bug_status']
    @product = config['product']
    @flags = config['flag']
    @format = config['format']
    @log = Logger.new(STDOUT)
    @log.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
  end

  def login
    system "bugzilla login" unless is_authenticated?
  end

  def query_bugs_to_change
    result = ''
    query = "bugzilla query -t '#{@bug_status}' -p '#{@product}' --flag=#{@flags} --bug_id=#{GitChangeLog.get_fixed_bugs} --outputformat='#{@format}'"
    @log.info(query)
    Open3.popen3(query) do |stdin, stdout, stderr, wait_thr|
      while line = stderr.gets
        puts line
      end
      result = stdout.read
    end
    result
  end

  private

  def is_authenticated?
    File.exist?("#{ENV['HOME']}/.bugzillacookies")
  end

end


configfile = "#{ENV['HOME']}/.bugquery.yaml"

if File.exist? configfile
  config = YAML.load_file(configfile)
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

query = BugzillaQuery.new(config)
query.login
bugs_to_change = query.query_bugs_to_change

if bugs_to_change.any?
  puts "Bugs to consider:\n#{bugs_to_change}"
else
  puts "No fixed bugs in status: #{config['bug_status']}"
end
