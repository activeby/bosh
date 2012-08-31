# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh
  module CloudStackCloud
    class Cloud < Bosh::Cloud
      attr_reader :cloudstack

      ##
      # Cloud initialization
      # Initialize BOSH CloudStack CPI
      #
      # @param [Hash] options cloud options
      #

      def initialize(options)
        @options = options.dup
        validate_options!

        @logger = Bosh::Clouds::Config.logger

        @agent_properties = @options["agent"] || {}
        @registry_properties = @options["registry"]

        registry_endpoint = @registry_properties["endpoint"]
        registry_user = @registry_properties["user"]
        registry_password = @registry_properties["password"]
        @registry = RegistryClient.new(registry_endpoint,
                                       registry_user,
                                       registry_password)

        cloudstack_config = @options['cloudstack']

        compute_init_options = {
                'cloudstack_api_key' => cloudstack_config["access_key_id"],
                'cloudstack_secret_access_key' => cloudstack_config["secret_access_key"],
                'cloudstack_host' => cloudstack_config["service_endpoint"]
        }

        compute_init_options[:provider] = "CloudStack"

        @cloudstack = Fog::Compute.new compute_init_options

        @disk_offerings_for_bosh = cloudstack_config['supported_disk_offerings']
        @default_availability_zone = cloudstack_config['default_availability_zone']

      end

      include OperationsHelpers

      include RegistryOperations

      include StemcellOperations

      include VmOperations

      include DiskOperations

      include NetworkOperations

      include DeploymentValidation

      private

      def not_implemented(method)
        raise Bosh::Clouds::NotImplemented,
              "Method `#{method}' is not implemented by #{self.class}"
      end

      def validate_options!
        unless @options.has_key?('cloudstack') && has_cloudstack_authentication?(@options['cloudstack'])
          raise ArgumentError, "Invalid CloudStack configuration parameters"
        end
      end

      def has_cloudstack_authentication?(cloudstack_config)
        cloudstack_config.is_a?(Hash) &&
        cloudstack_config['access_key_id'] &&
        cloudstack_config['secret_access_key'] &&
        cloudstack_config['service_endpoint']
      end

      ##
      # Raises CloudError exception
      #
      def cloud_error(message)
        if @logger
          @logger.error(message)
        end
        raise Bosh::Clouds::CloudError, message
      end

    end
  end
end
