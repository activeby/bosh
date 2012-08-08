module Bosh
  module CloudStackCloud
    module DiskOperations
      ##
      # Creates a disk (possibly lazily) that will be attached later to a VM. When
      # VM locality is specified the disk will be placed near the VM so it won't have to move
      # when it's attached later.
      #
      # @param [Integer] size disk size in MB
      # @param [optional, String] server_id vm id if known of the VM that this disk will
      #                           be attached to
      # @return [String] opaque id later used by {#attach_disk}, {#detach_disk}, and {#delete_disk}
      DEFAULT_AVAILABILITY_ZONE = "2"
      def create_disk(size, server_id = nil)
        with_thread_name("create_disk(#{size}, #{server_id})") do
          unless size.kind_of?(Integer)
            raise ArgumentError, "disk size needs to be an integer"
          end

          if size < 1024
            cloud_error("CloudStack CPI minimum disk size is 1 GiB")
          end

          if size > 1024 * 1000
            cloud_error("CloudStack CPI maximum disk size is 1 TiB")
          end
          #############################
          if server_id
            server = @cloudstack.servers.get[server_id]
            availability_zone = server.availability_zone
          else
            availability_zone = DEFAULT_AVAILABILITY_ZONE
          end
          #############################
          volume_params = {
              :name => "volume-#{generate_unique_name}",
              #:size => (size / 1024.0).ceil,
              :zone_id => availability_zone,
              :disk_offering_id => "141"
          }
          ####
          #volume = @ec2.volumes.create(volume_params)
          #@logger.info("Creating volume `#{volume.id}'")
          #wait_resource(volume, :available)
          #
          #volume.id
          ####

          #@logger.info("Creating new volume...")
          volume = @cloudstack.volumes.create(volume_params)
          #salsa: check what is returned#puts volume.class
          state = volume.status

          #@logger.info("Creating new volume `#{volume.id}', state is `#{state}'")
          wait_resource(volume, state, :available)

          volume.id.to_s
        end
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

      private

      def generate_unique_name
        UUIDTools::UUID.random_create.to_s
      end
    end
  end
end