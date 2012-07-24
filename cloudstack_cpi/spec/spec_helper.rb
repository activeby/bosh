ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

require "rspec"
require 'debugger'

require 'cloud'
require 'cloud/cloudstack'

require 'hooks'

class CloudStackSpecConfig
  attr_accessor :logger, :uuid
end

config = CloudStackSpecConfig.new
config.logger = Logger.new(STDOUT)
config.logger.level = Logger::ERROR

Bosh::Clouds::Config.configure(config)

