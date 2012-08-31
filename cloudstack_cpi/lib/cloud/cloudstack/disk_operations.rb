# Copyright (c) 2003-2012 Active Cloud, Inc.

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

          availability_zone = determine_availability_zone(server_id)

          disk_offering_id = determine_disk_offering(size)

          volume_params = {
              :name => "volume-#{generate_unique_name}",
              :zone_id => availability_zone,
              :disk_offering_id => disk_offering_id.to_s
          }

          @logger.info("Creating new volume...")
          volume = @cloudstack.volumes.create(volume_params)
          wait_resource(volume, "Allocated", :state)
          state = volume.state
          @logger.info("New volume `#{volume.id}' created, state is `#{state}'")

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
          state = volume.ready?
          cloud_error("Cannot delete volume `#{disk_id}'.") if state != true
          @logger.info("Deleting volume `#{disk_id}' with state `#{state}'")
          response = volume.destroy
          if response
            @logger.info("Volume `#{disk_id}' deleted")
          end
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
          volume = @cloudstack.volumes.get(disk_id)
          volume.attach(server_id)
          volume.wait_for{volume.send(:server_id)}
          @logger.info("Volume is successfully attached.")

          deviceid = get_disk_property(disk_id, "deviceid")
          server = @cloudstack.servers.get(server_id)
          update_registry_settings(server) do |settings|
            settings["disks"] ||= {}
            settings["disks"]["persistent"] ||= {}
            settings["disks"]["persistent"][disk_id] = deviceid
          end
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
          volume = @cloudstack.volumes.get(disk_id)
          volume.detach
          volume.wait_for{volume.send(:server_id) == nil}
          @logger.info("Volume is successfully detached.")

          server = @cloudstack.servers.get(server_id)
          update_registry_settings(server) do |settings|
            settings["disks"] ||= {}
            settings["disks"]["persistent"] ||= {}
            settings["disks"]["persistent"].delete(disk_id)
          end
        end
      end

      def get_disk_property(disk_id, property = "all")
        with_thread_name("get_disk_property(#{disk_id}, #{property})") do
          disk_properties = @cloudstack.list_volumes('id' => disk_id)["listvolumesresponse"]["volume"].first
          if property == "all"
            return disk_properties
          end
          return disk_properties[property.to_s]
        end
      end

      private

      def mb_to_gb(size)
        (size / 1024.0).ceil
      end

      def determine_availability_zone(server_id)
        if server_id
          server = @cloudstack.servers.get(server_id)
          server.zone_id
        else
          @default_availability_zone
        end
      end

      def determine_disk_offering size
        available_offerings = @cloudstack.list_disk_offerings['listdiskofferingsresponse']['diskoffering']
        offerings = available_offerings.select {|ofr| @disk_offerings_for_bosh.include?(ofr['id']) }

        size_gb = mb_to_gb size
        offerings.sort_by! { |ofr| ofr['disksize'] }
        offerings.each do |offering|
          return offering['id'] if offering['disksize'] >= size_gb
        end

        cloud_error "Cannot find disk offering with size greater than #{size} Mb"
      end

      ## attaching volumes to mountpoint defined by deviceid doesn't work for cloudstack CPI 2.2.8
      ## cloudstack mounts the volumes in alphabetical order of /dev/vd* no matter deviceid
      # Attaches an CloudStack volume to an CloudStack server (from OpenStack CPI)
      # @param [Fog::Compute::OpenStack::Server] server CloudStack server
      # @param [Fog::Compute::OpenStack::Volume] volume CloudStack volume
      #def attach_volume(server, volume)
      #  volume_attachments = @cloudstack.list_volumes(virtualmachineid: server.id)["listvolumesresponse"]["volume"]
      #  device_ids = Set.new(volume_attachments.map {|v| v["deviceid"] })
      #  new_attachment = nil
      #  (1..9).each do |id|
      #    dev_name = "/dev/vd#{id}" # create a mapping for 1..9 to b..j
      #    if device_ids.include?(dev_name)
      #      @logger.warn("`#{dev_name}' on `#{server.id}' is taken")
      #      next
      #    end
      #    @logger.info("Attaching volume `#{volume.id}' to `#{server.id}', device name is `#{dev_name}'")
      #    if volume.attach(server.id, device_id)
      #      state = volume.status
      #      wait_resource(volume, state, :"in-use")
      #      new_attachment = dev_name
      #    end
      #    break
      #  end
      #
      #  if new_attachment.nil?
      #    cloud_error("Server has too many disks attached")
      #  end
      #
      #  new_attachment
      #end
    end
  end
end