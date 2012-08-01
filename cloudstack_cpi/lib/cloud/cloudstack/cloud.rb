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
      def initialize()
        not_implemented(:initialize)
      end

      def initialize(options)
        @options = options.dup

        validate_options!

        compute_init_options = @options['cloudstack'].select { |key, _|
          %w(cloudstack_api_key cloudstack_secret_access_key cloudstack_host).include? key
        }
        compute_init_options[:provider] = "CloudStack"

        @compute = Fog::Compute.new compute_init_options


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
      # @param [Hash] networks list of networks and their settings needed for this VM
      # @param [optional, String, Array] disk_locality disk id(s) if known of the disk(s) that will be
      #                                    attached to this vm
      # @param [optional, Hash] env environment that will be passed to this vm
      # @return [String] opaque id later used by {#configure_networks}, {#attach_disk},
      #                  {#detach_disk}, and {#delete_vm}
      def create_vm(agent_id, stemcell_id, resource_pool,
        networks, disk_locality = nil, env = nil)
      not_implemented(:create_vm)
      end

      ##
      # Deletes a VM
      #
      # @param [String] vm vm id that was once returned by {#create_vm}
      # @return nil
      def delete_vm(vm_id)
        not_implemented(:delete_vm)
      end

      ##
      # Reboots a VM
      #
      # @param [String] vm vm id that was once returned by {#create_vm}
      # @param [Optional, Hash] CPI specific options (e.g hard/soft reboot)
      # @return nil
      def reboot_vm(vm_id)
        not_implemented(:reboot_vm)
      end

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

      ##
      # Creates a disk (possibly lazily) that will be attached later to a VM. When
      # VM locality is specified the disk will be placed near the VM so it won't have to move
      # when it's attached later.
      #
      # @param [Integer] size disk size in MB
      # @param [optional, String] vm_locality vm id if known of the VM that this disk will
      #                           be attached to
      # @return [String] opaque id later used by {#attach_disk}, {#detach_disk}, and {#delete_disk}
      def create_disk(size, vm_locality = nil)
        not_implemented(:create_disk)
      end

      ##
      # Deletes a disk
      # Will raise an exception if the disk is attached to a VM
      #
      # @param [String] disk disk id that was once returned by {#create_disk}
      # @return nil
      def delete_disk(disk_id)
        not_implemented(:delete_disk)
      end

      ##
      # Attaches a disk
      #
      # @param [String] vm vm id that was once returned by {#create_vm}
      # @param [String] disk disk id that was once returned by {#create_disk}
      # @return nil
      def attach_disk(vm_id, disk_id)
        not_implemented(:attach_disk)
      end

      ##
      # Detaches a disk
      #
      # @param [String] vm vm id that was once returned by {#create_vm}
      # @param [String] disk disk id that was once returned by {#create_disk}
      # @return nil
      def detach_disk(vm_id, disk_id)
        not_implemented(:detach_disk)
      end

      ##
      # Validates the deployment
      # @api not_yet_used
      def validate_deployment(old_manifest, new_manifest)
        not_implemented(:validate_deployment)
      end

      private

      def not_implemented(method)
        raise Bosh::Clouds::NotImplemented,
        "`#{method}' is not implemented by #{self.class}"
      end

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
    end
  end
end

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2

