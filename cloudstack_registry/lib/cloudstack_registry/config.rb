# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh::CloudstackRegistry

  class << self

    attr_accessor :logger
    attr_accessor :http_port
    attr_accessor :http_user
    attr_accessor :http_password
    attr_accessor :db

    attr_writer :cloudstack

    def configure(config)
      validate_config(config)

      @logger ||= Logger.new(config["logfile"] || STDOUT)

      if config["loglevel"].kind_of?(String)
        @logger.level = Logger.const_get(config["loglevel"].upcase)
      end

      @http_port = config["http"]["port"]
      @http_user = config["http"]["user"]
      @http_password = config["http"]["password"]

      @cloudstack_properties = config["cloudstack"]

      @cloudstack_options = {
        :provider => "CloudStack",
        :cloudstack_api_key => @cloudstack_properties["access_key_id"],
        :cloudstack_secret_access_key => @cloudstack_properties["secret_access_key"],
        :cloudstack_host => @cloudstack_properties["service_endpoint"]
      }

      @db = connect_db(config["db"])
    end

    def cloudstack
      cloudstack ||= Fog::Compute.new(@cloudstack_options)
    end

    def connect_db(db_config)
      connection_options = {
        :max_connections => db_config["max_connections"],
        :pool_timeout => db_config["pool_timeout"]
      }

      db = Sequel.connect(db_config["database"], connection_options)
      db.logger = @logger
      db.sql_log_level = :debug
      db
    end

    def validate_config(config)
      unless config.is_a?(Hash)
        raise ConfigError, "Invalid config format, Hash expected, " \
                           "#{config.class} given"
      end

      unless config.has_key?("http") && config["http"].is_a?(Hash)
        raise ConfigError, "HTTP configuration is missing from " \
                           "config file"
      end

      unless config.has_key?("db") && config["db"].is_a?(Hash)
        raise ConfigError, "Database configuration is missing from " \
                           "config file"
      end

      unless config.has_key?("cloudstack") && config["cloudstack"].is_a?(Hash)
        raise ConfigError, "CloudStack configuration is missing from " \
                           "config file"
      end
    end

  end

end
