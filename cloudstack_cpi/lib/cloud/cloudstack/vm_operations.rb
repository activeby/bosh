module Bosh
  module CloudStackCloud
    module VmOperations
      ##
      # Creates a VM - creates (and powers on) a VM from a stemcell with the proper resources
      # and on the specified network. When disk locality is present the VM will be placed near
      # the provided disk so it won't have to move when the disk is attached later.
      #
      # Sample networking config:
      #  {"network_a" =>
      #    {
      #      "netmask"          => "255.255.248.0",
      #      "ip"               => "172.30.41.40",
      #      "gateway"          => "172.30.40.1",
      #      "dns"              => ["172.30.22.153", "172.30.22.154"],
      #      "cloud_properties" => {"name" => "VLAN444"}
      #    }
      #  }
      #
      # Sample resource pool config (CPI specific):
      #  {
      #    "ram"  => 512,
      #    "disk" => 512,
      #    "cpu"  => 1
      #  }
      # or similar for EC2:
      #  {"name" => "m1.small"}
      #
      # @param [String] agent_id UUID for the agent that will be used later on by the director
      #                 to locate and talk to the agent
      # @param [String] stemcell stemcell id that was once returned by {#create_stemcell}
      # @param [Hash] resource_pool cloud specific properties describing the resources needed
      #               for this VM
      # @param [Hash] network_spec network properties for this VM
      # @param [optional, String, Array] disk_locality disk id(s) if known of the disk(s) that will be
      #                                    attached to this vm
      # @param [optional, Hash] env environment that will be passed to this vm
      # @return [String] opaque id later used by {#configure_networks}, {#attach_disk},
      #                  {#detach_disk}, and {#delete_vm}
      def create_vm(agent_id, stemcell_id, resource_pool,
          network_spec, disk_locality = nil, env = nil)
        not_implemented(:create_vm)
      end

      ##
      # Deletes a VM
      #
      # @param [String] vm server_id that was once returned by {#create_vm}
      # @return nil
      def delete_vm(server_id)
        not_implemented(:delete_vm)
      end

      ##
      # Reboots a VM
      #
      # @param [String] vm server_id that was once returned by {#create_vm}
      # @param [Optional, Hash] CPI specific options (e.g hard/soft reboot)
      # @return nil
      def reboot_vm(server_id)
        not_implemented(:reboot_vm)
      end
    end
  end
end