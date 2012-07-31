#!/usr/bin/env ruby

#require 'fog'

$:.unshift(File.expand_path("../../lib", __FILE__))
require "bosh_cloudstack_cpi"

cld = Bosh::CloudStackCloud::Cloud.new

