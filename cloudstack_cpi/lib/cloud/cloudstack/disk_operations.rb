module Bosh
  module CloudStackCloud
    module DiskOperations
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
    end
  end
end