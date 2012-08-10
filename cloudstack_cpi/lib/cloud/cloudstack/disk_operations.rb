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
      # to use size parameter in cloudstack a disk_offering must be created with "iscustomized"=>true
      # create disk method is not completed yet.

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

          if server_id
            server = @cloudstack.servers.get(server_id)
            #puts server.class
            availability_zone = server.zone_id
          else
            availability_zone = DEFAULT_AVAILABILITY_ZONE
          end

          volume_params = {
              :name => "volume-#{generate_unique_name}",
              #:size => (size / 1024.0).ceil,
              :zone_id => availability_zone,
              :disk_offering_id => "141"
          }

          @logger.info("Creating new volume...")
          volume = @cloudstack.volumes.create(volume_params)
          #puts volume.class
          volume.wait_for{volume.state == 'Allocated'}
          state = volume.state
          @logger.info("New volume `#{volume.id}' created, state is `#{state}'")
          #wait_resource(volume.ready?, :Allocated)
          #volume.wait_for{'Allocated'}

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
        with_thread_name("delete_disk(#{disk_id})") do
          volume = @cloudstack.volumes.get(disk_id)
          #state = volume.ready?
          state = volume.state
          cloud_error("Cannot delete volume `#{disk_id}', state is #{state}") if state.to_sym != :Allocated
          @logger.info("Deleting volume `#{disk_id}' with state `#{state}'")
          volume.destroy
          #done = volume.destroy
          #cloud_error("Cannot delete volume `#{disk_id}', state is #{state}") if done != true
          #state = volume.ready?
          #wait_resource(volume, state, :deleted)
          @logger.info("Volume `#{disk_id}' deleted")
        end
      end

      ##
      # Attaches a disk
      #
      # @param [String] vm vm id that was once returned by {#create_vm}
      # @param [String] disk disk id that was once returned by {#create_disk}
      # @return nil
      def attach_disk(server_id, disk_id)
        with_thread_name("attach_disk(#{server_id}, #{disk_id})") do
          server = @cloudstack.servers.get(server_id)
          volume = @cloudstack.volumes.get(disk_id)
          volume.attach(server_id)
          #device_name = attach_volume(server, volume)

          #update_agent_settings(server) do |settings|
          #  settings["disks"] ||= {}
          #  settings["disks"]["persistent"] ||= {}
          #  settings["disks"]["persistent"][disk_id] = device_name
          #end
        end
      end

      ##
      # Detaches a disk
      #
      # @param [String] vm vm id that was once returned by {#create_vm}
      # @param [String] disk disk id that was once returned by {#create_disk}
      # @return nil
      def detach_disk(server_id, disk_id)
        with_thread_name("detach_disk(#{server_id}, #{disk_id})") do
          server = @cloudstack.servers.get(server_id)
          volume = @cloudstack.volumes.get(disk_id)
          volume.detach
          #detach_volume(server, volume)

          #update_agent_settings(server) do |settings|
          #  settings["disks"] ||= {}
          #  settings["disks"]["persistent"] ||= {}
          #  settings["disks"]["persistent"].delete(disk_id)
          #end
        end
      end

      private

      def generate_unique_name
        UUIDTools::UUID.random_create.to_s
      end

      def update_agent_settings(server)
        unless block_given?
          raise ArgumentError, "block is not provided"
        end

        # TODO uncomment to test registry
        @logger.info("Updating server settings for `#{server.id}'")
        settings = @registry.read_settings(server.name)
        yield settings
        @registry.update_settings(server.name, settings)
      end

      ## TODO rewrite attach and detach for cloudstack
      # Attaches an OpenStack volume to an OpenStack server
      # @param [Fog::Compute::OpenStack::Server] server OpenStack server
      # @param [Fog::Compute::OpenStack::Volume] volume OpenStack volume
      def attach_volume(server, volume)
        volume_attachments = @cloudstack.get_server_volumes(server.id).body['volumeAttachments']
        device_names = Set.new(volume_attachments.collect! {|v| v["device"] })
        new_attachment = nil

        ("c".."z").each do |char|
          dev_name = "/dev/vd#{char}"
          if device_names.include?(dev_name)
            @logger.warn("`#{dev_name}' on `#{server.id}' is taken")
            next
          end
          @logger.info("Attaching volume `#{volume.id}' to `#{server.id}', device name is `#{dev_name}'")
          if volume.attach(server.id, dev_name)
            state = volume.status
            wait_resource(volume, state, :"in-use")
            new_attachment = dev_name
          end
          break
        end

        if new_attachment.nil?
          cloud_error("Server has too many disks attached")
        end

        new_attachment
      end

      ##
      # Detaches an OpenStack volume from an OpenStack server
      # @param [Fog::Compute::OpenStack::Server] server OpenStack server
      # @param [Fog::Compute::OpenStack::Volume] volume OpenStack volume
      def detach_volume(server, volume)
        volume_attachments = @openstack.get_server_volumes(server.id).body['volumeAttachments']
        device_map = volume_attachments.collect! {|v| v["volumeId"] }

        if !device_map.include?(volume.id)
          cloud_error("Disk `#{volume.id}' is not attached to server `#{server.id}'")
        end

        state = volume.status
        @logger.info("Detaching volume `#{volume.id}' from `#{server.id}', state is `#{state}'")
        volume.detach(server.id, volume.id)
        wait_resource(volume, state, :available)
      end
    end
  end
end