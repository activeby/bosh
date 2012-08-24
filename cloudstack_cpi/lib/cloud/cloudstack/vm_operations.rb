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
          network_spec, disk_locality = nil, environment = nil)
        with_thread_name("create_vm(#{agent_id}, ...)") do
          puts network_spec.inspect
          network_configurator = Bosh::CloudStackCloud::NetworkOperations::NetworkConfigurator.new(network_spec)

          server_name = "vm-#{generate_unique_name}"

          security_groups = network_configurator.security_groups(@default_security_groups)
          @logger.debug("using security groups: #{security_groups.join(', ')}") if @logger

          image = @cloudstack.images.find { |i| i.id == stemcell_id }
          if image.nil?
            cloud_error("CloudStack CPI: image #{stemcell_id} not found")
          end

          puts  "resource_pool:\n"
          puts  resource_pool.inspect
#          puts resource_pool["instance_type"]
#          puts "\n\@cloudstack.methods : "+ cloudstack.methods.sort.join(" ").to_s+"\n"

          flavor = @cloudstack.flavors.find { |f| f.name == resource_pool["instance_type"] }
          if flavor.nil?
            cloud_error("CloudStack CPI: flavor #{resource_pool["instance_type"]} not found")
          end

          zones = @cloudstack.zones
#          puts "zones:\n"
#          puts zones.inspect
          puts  "resource_pool:\n"
          puts  resource_pool.inspect

          zone = @cloudstack.zones.find { |z| z.id == resource_pool["availability_zone"]}
          if zone.nil?
            cloud_error("CloudStack CPI: zone #{resource_pool["availability_zone"]} not found")
          end

          # http://download.cloud.com/releases/2.2.0/api_2.2.8/user/deployVirtualMachine.html
          # CloudStack 2.2.8 User API Reference
          #
          # deployVirtualMachine
          #
          # Creates and automatically starts a virtual machine
          # based on a service offering, disk offering, and template.
          # required params
          #  :image_id=>1095,
          #  :flavor_id=>27,
          #  :zone_id=>4,
          server_params = {
            :flavor_id => flavor.id,
            :image_id => image.id,
            :zone_id => zone.id,
            # account, diskofferingid
            :displayname => server_name, # an optional user generated name for the virtual machine
            # domainid, group, hostid, hypervisor, keypair
            :name => server_name, # host name for the virtual machine
            # networkids, securitygroupids
            # :securitygroupnames => "default"
            # size, userdata
          }

          server = @cloudstack.servers.create(server_params)
          state = server.state

          @logger.info("Creating new server `#{server.id}', state is `#{state}'")
          wait_resource(server, "Running")

          @logger.info("Configuring network for `#{server.id}'")
          network_configurator.configure(@cloudstack, server)

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

      private

      ##
      # Generates initial agent settings. These settings will be read by agent
      # from CloudStack registry (also a BOSH component) on a target server. Disk
      # conventions for CloudStack are:
      # system disk: /dev/vda
      # CloudStack volumes can be configured to map to other device names later (vdc
      # through vdz, also some kernels will remap vd* to xvd*).
      #
      # @param [String] agent_id Agent id (will be picked up by agent to
      #   assume its identity
      # @param [Hash] network_spec Agent network spec
      # @param [Hash] environment
      # @return [Hash]
      def initial_agent_settings(server_name, agent_id, network_spec, environment)
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

    end
  end
end
