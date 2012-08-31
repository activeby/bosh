# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh::CloudStackCloud::RegistryOperations
  class RegistryClient
    include Bosh::CloudStackCloud::OperationsHelpers

    attr_reader :endpoint
    attr_reader :user
    attr_reader :password

    def initialize(endpoint, user, password)

      @logger = Bosh::Clouds::Config.logger
      @endpoint = endpoint

      unless @endpoint =~ /^http:\/\//
        @endpoint = "http://#{@endpoint}"
      end

      @user = user
      @password = password

      auth = Base64.encode64("#{@user}:#{@password}").gsub("\n", "")

      @headers = {
          "Accept" => "application/json",
          "Authorization" => "Basic #{auth}"
      }

      @client = HTTPClient.new
    end

    ##
    # Update server settings in the registry
    # @param [String] server_name CloudStack server name
    # @param [Hash] settings New agent settings
    # @return [Boolean]
    def update_settings(server_name, settings)
      unless settings.is_a?(Hash)
        raise ArgumentError, "Invalid settings format, " \
                             "Hash expected, #{settings.class} given"
      end

      payload = Yajl::Encoder.encode(settings)
      url = "#{@endpoint}/servers/#{server_name}/settings"

      response = @client.put(url, payload, @headers)

      if response.status != 200
        cloud_error("Cannot update settings for `#{server_name}', " \
                    "got HTTP #{response.status}")
      end

      true
    end

    ##
    # Read server settings from the registry
    # @param [String] server_name CloudStack server name
    # @return [Hash] Agent settings
    def read_settings(server_name)
      url = "#{@endpoint}/servers/#{server_name}/settings"

      response = @client.get(url, {}, @headers)

      if response.status != 200
        cloud_error("Cannot read settings for `#{server_name}', " \
                    "got HTTP #{response.status}")
      end

      body = Yajl::Parser.parse(response.body)

      unless body.is_a?(Hash)
        cloud_error("Invalid registry response, Hash expected, " \
                    "got #{body.class}: #{body}")
      end

      settings = Yajl::Parser.parse(body["settings"])

      unless settings.is_a?(Hash)
        cloud_error("Invalid settings format, " \
                    "Hash expected, got #{settings.class}: " \
                    "#{settings}")
      end

      settings

    rescue Yajl::ParseError
      cloud_error("Cannot parse settings for `#{server_name}'")
    end

    ##
    # Delete server settings from the registry
    # @param [String] server_name CloudStack server name
    # @return [Boolean]
    def delete_settings(server_name)
      url = "#{@endpoint}/servers/#{server_name}/settings"

      response = @client.delete(url, @headers)

      if response.status != 200
        cloud_error("Cannot delete settings for `#{server_name}', " \
                    "got HTTP #{response.status}")
      end

      true
    end

  end

end