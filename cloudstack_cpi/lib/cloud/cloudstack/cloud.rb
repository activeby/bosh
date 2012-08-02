require 'fog'

module Bosh
  module CloudStackCloud
    class Cloud < Bosh::Cloud
      ##
      # Cloud initialization
      # Initialize BOSH OpenStack CPI
      #
      # @param [Hash] options cloud options
      #
      def initialize(options)
        @options = options.dup
        validate_options!

        @logger = Bosh::Clouds::Config.logger

        compute_init_options = @options['cloudstack'].select { |key, _|
          %w(cloudstack_api_key cloudstack_secret_access_key cloudstack_host).include? key
        }
        compute_init_options[:provider] = "CloudStack"

        @cloudstack = Fog::Compute.new compute_init_options


#options[:cloudstack_session_id] = '?'
#options[:cloudstack_session_key] = '?'
#options[:cloudstack_path] = '/client/api'
#options[:cloudstack_port] = 443
#options[:cloudstack_scheme] = 'https'
#options[:cloudstack_persistent] = false

        #vms = compute.list_virtual_machines
        #p vms

# create volume
#        compute.volumes.create()

# copy image content to the volume
#        ``

# create template from the volume
#        compute.images.create(template_create_params)
      end

      include StemcellOperations

      include VmOperations

      include DiskOperations

      include NetworkConfiguration

      include DeploymentValidation

      private

      def validate_options!
        unless @options.has_key?('cloudstack') && has_cloudstack_authentication?(@options['cloudstack'])
          raise ArgumentError, "Invalid CloudStack configuration parameters"
        end
      end

      def has_cloudstack_authentication?(cloudstack_config)
        cloudstack_config.is_a?(Hash) &&
        cloudstack_config['cloudstack_api_key'] &&
        cloudstack_config['cloudstack_secret_access_key'] &&
        cloudstack_config['cloudstack_host']
      end

      def cloud_error(message)
        if @logger
          @logger.error(message)
        end
        raise Bosh::Clouds::CloudError, message
      end
    end
  end
end

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2