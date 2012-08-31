# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh
  module CloudStackCloud
    module NetworkOperations
      ##
      # Configures networking on existing CloudStack VM.
      #
      # @param [String] vm server_id that was once returned by {#create_vm}
      # @param [Hash] network_spec (see networks in instance_manager.rb) network properties for this VM
      #               same as the network_spec argument in {#create_vm}
      # @return nil
      # WHEN READY PUT THIS INTO cloud.rb
      def configure_networks(server_id, network_spec)
        with_thread_name("configure_networks(#{server_id}, ...)") do
          @logger.info("Configuring `#{server_id}' to use the following " \
                     "network settings: #{network_spec.pretty_inspect}")

          server = @cloudstack.servers.get(server_id)
          network_configurator = NetworkConfigurator.new(network_spec)
          network_configurator.configure(@cloudstack, server)

          @logger.info("Updating user-data for virtualmachine id=`#{server.id}'")
          userdata = "{'vm' => {'name' => #{server.name}}}"
          update_userdata(server.id, userdata)

          update_registry_settings(server) do |settings|
            settings["networks"] = network_spec
          end
        end
      end
    end
  end
end