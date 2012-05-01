#!/usr/bin/ruby

require 'pathname'
@root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
$: << @root.to_s

$0 = "collectd-plot"

require 'lib/collectd-plot'

use CollectdPlot::Hosts
run Sinatra::Base
