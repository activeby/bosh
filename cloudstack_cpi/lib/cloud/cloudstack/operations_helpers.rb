# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh
  module CloudStackCloud
    module OperationsHelpers

      DEFAULT_TIMEOUT = 3600 # seconds

      def generate_unique_name
        UUIDTools::UUID.random_create.to_s
      end

      # could be useful to get properties of VM or disk...
      def get_properties(resource, id, property)

      end

      ##
      # Encodes the data with base64 as it is required by CloudStack API
      def base64encode_data(userdata)
        Base64.urlsafe_encode64(userdata)
      end

      ##
      # Writes user-data for VM into http://10.1.0.1/latest/user-data
      def update_userdata(server_id, userdata)
        registry_endpoint = @registry.endpoint
        userdata_extended = "{#{userdata}, 'registry' => {'endpoint' => "#{registry_endpoint}"}}"
        userdata_encoded = base64encode_data("#{userdata_extended}")
        @cloudstack.update_virtual_machine({:id => "#{server_id}", :userdata => "#{userdata_encoded}"})
        true
      end

      ##
      # Wait until the resource will be put into the target state
      def wait_resource(resource, target_state, state_method = :state, timeout = DEFAULT_TIMEOUT)
        desc = resource.to_s
        @logger.debug("Waiting for #{desc} to be #{target_state}") if @logger

        started_at = Time.now
        loop do
          error_if_timed_out!(started_at, timeout, desc, target_state)

          state = resource.send(state_method)

          ensure_no_error_state!(desc, state, target_state)

          @logger.debug("#{desc} has state #{state}.") if @logger
          break if state == target_state

          sleep(1)
          resource.reload
        end

        if @logger
          total = Time.now - started_at
          @logger.debug("#{desc} is now #{target_state}, took #{total}s")
        end
      end

      ##
      # Wait until the server will be deleted
      # we must catch exception when "Fog" can't find VM
      def wait_deleted_server(resource, target_state, state_method = :state, timeout = DEFAULT_TIMEOUT)
        begin
          wait_resource(resource, target_state, state_method, timeout)
        rescue
          find_server = @cloudstack.servers.find { |s| s.id == resource.id }
          raise if find_server != nil
        end
      end

      private
      def error_if_timed_out!(started_at, timeout, desc, target_state)
        duration = Time.now - started_at
        if duration > timeout
          cloud_error("Timed out waiting for #{desc} to be #{target_state}")
        end
      end

      def ensure_no_error_state!(desc, state, target_state)
        # This is not a very strong convention, but some resources
        # have 'error' and 'failed' states, we probably don't want to keep
        # waiting if we're in these states. Alternatively we could introduce a
        # set of 'loop breaker' states but that doesn't seem very helpful
        # at the moment
        if state == :error || state == :failed
          cloud_error("#{desc} state is #{state}, expected #{target_state}")
        end
      end
    end
  end
end
