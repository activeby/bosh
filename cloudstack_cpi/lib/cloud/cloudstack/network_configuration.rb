module Bosh
  module CloudStackCloud
    module NetworkConfiguration
      ##
      # Configures networking an existing VM.
      #
      # @param [String] vm vm id that was once returned by {#create_vm}
      # @param [Hash] networks list of networks and their settings needed for this VM,
      #               same as the networks argument in {#create_vm}
      # @return nil
      def configure_networks(vm_id, networks)
        not_implemented(:configure_networks)
      end
    end
  end
end