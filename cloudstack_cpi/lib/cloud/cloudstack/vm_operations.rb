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
        with_thread_name("create_vm(#{agent_id}, ...)") do
          network_configurator = NetworkConfigurator.new(network_spec)

          server_name = "vm-#{generate_unique_name}"

          security_groups = network_configurator.security_groups(@default_security_groups)
          @logger.debug("using security groups: #{security_groups.join(', ')}")

          image = @openstack.images.find { |i| i.id == stemcell_id }
          if image.nil?
            cloud_error("OpenStack CPI: image #{stemcell_id} not found")
          end

          flavor = @openstack.flavors.find { |f| f.name == resource_pool["instance_type"] }
          if flavor.nil?
            cloud_error("OpenStack CPI: flavor #{resource_pool["instance_type"]} not found")
          end

          # http://download.cloud.com/releases/2.2.0/api_2.2.8/user/deployVirtualMachine.html
          # CloudStack 2.2.8 User API Reference
          #
          # deployVirtualMachine
          #
          # Creates and automatically starts a virtual machine
          # based on a service offering, disk offering, and template.
          #
          #  :image_id=>1095,
          #  :flavor_id=>27,
          #  :zone_id=>4,
          server_params = {
            :flavor_id => flavor.id,
            :image_id => image.id,
            # zone_id, account, diskofferingid
            :displayname => server_name, # an optional user generated name for the virtual machine
            # domainid, group, hostid, hypervisor, keypair
            :name => server_name, # host name for the virtual machine
            # networkids, securitygroupids
            :securitygroupnames => "default"
            # size, userdata        
          }

          server_params[:zone_id] = 4 # zoneid - availability zone for the vm

          server = @cloudstack.servers.create(server_params)
          state = server.state

          @logger.info("Creating new server `#{server.id}', state is `#{state}'")
          wait_resource(server, state, :active, :state)

          @logger.info("Configuring network for `#{server.id}'")
          network_configurator.configure(@openstack, server)

          @logger.info("Updating server settings for `#{server.id}'")
          settings = initial_agent_settings(server_name, agent_id, network_spec, environment)
          @registry.update_settings(server.name, settings)

          server.id.to_s
        end
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
