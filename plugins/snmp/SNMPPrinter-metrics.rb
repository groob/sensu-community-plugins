#!/usr/bin/env ruby
# This script outputs printer metrics like toner levels and pagecount.
#Example:
#
# ./SNMPPrinter-metrics.rb -h 192.168.168.1 -C public
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'snmp'
include SNMP

class SNMPGraphite < Sensu::Plugin::Metric::CLI::Graphite

  option :host,
    :short => '-h host',
    :boolean => true,
    :default => "127.0.0.1",
    :required => true

  option :community,
    :short => '-C snmp community',
    :default => "public"

  def run
    # consumables = Hash.new
    consum = '1.3.6.1.2.1.43.11.1.1.6.1'
    amount_oid = '1.3.6.1.2.1.43.11.1.1.9.1'
    manager = SNMP::Manager.new(:host => "#{config[:host]}", :community => "#{config[:community]}", :Timeout  => 10, :version => :SNMPv1)
    manager.walk(consum) do |row|
      row.each do |consumable_name|
        x = consumable_name.oid.last
        amount = manager.get("#{amount_oid}.#{x}")
        amount.each_varbind do |consumable_amount|
          output "snmp.printer.#{config[:host]}.#{consumable_name.value.gsub(' ','_').gsub(',','')} #{consumable_amount.value} #{Time.now.to_i}"
        end #amount
      end #row
    end #walk
    pages = manager.get('1.3.6.1.2.1.43.10.2.1.4.1.1')
    pages.each_varbind do |page|
      output "snmp.printer.#{config[:host]}.pagecount #{page.value} #{Time.now.to_i}"
    end #pages
    manager.walk('1.3.6.1.2.1.43.8.2.1.10.1') do |row|
      row.each do |tray|
        output "snmp.printer.#{config[:host]}.Tray#{tray.oid.last} #{tray.value} #{Time.now.to_i}"
      end
    end
    manager.close
    ok
  end #run
end #class
