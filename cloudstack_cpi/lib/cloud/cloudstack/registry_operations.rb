# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh
  module CloudStackCloud
    module RegistryOperations
      # here all the operations with cloudstack_registry

      ##
      # Generates initial settings for VM. These settings will be read by agent
      # from CloudStack registry (also a BOSH component) on a target server. Disk
      # conventions for CloudStack are:
      # system disk: /dev/vda
      # CloudStack volumes can be configured to map to other device names later (vdc
      # through vdz, also some kernels will remap vd* to xvd*).
      #
      # @param [String] agent_id Agent id (will be picked up by agent to
      # assume its identity) is provided when using CPI
      # @param [Hash] network_spec Agent network spec
      # @param [Hash] environment
      # @return [Hash]
      def initial_registry_settings(server_name, agent_id, network_spec, environment)
        settings = {
          "vm" => {
            "name" => server_name
          },
          "agent_id" => agent_id,
          "networks" => network_spec,
          "disks" => {
            "system" => "/dev/vda",
            "ephemeral" => "/dev/vdb",
            "persistent" => {}
          }
        }

        settings["env"] = environment if environment
        settings.merge(@agent_properties)
      end

      def update_registry_settings(server)
        unless block_given?
          raise ArgumentError, "block is not provided"
        end

        @logger.info("Updating registry settings for virtualmachine name=`#{server.name}'")
        settings ||= @registry.read_settings(server.name) rescue Bosh::Clouds::CloudError; {}
        yield settings
        @registry.update_settings(server.name, settings)
      end

      def read_registry_settings(server_name)
        @registry.read_settings(server_name)
      end

    end
  end
end