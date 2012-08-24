# Copyright (c) 2009-2012 VMware, Inc.

#module Bosh::CloudStackCloud
# see create_disk and update this module
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
      # Raises CloudError exception
      #
      def cloud_error(message)
        if @logger
          @logger.error(message)
        end
        raise Bosh::Clouds::CloudError, message
      end

      # wait until the resource will be put into the target state
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

      def show_methods_for_object(object)
        name = object.class.name
        puts "\n#{name} methods: "+ object.methods.sort.join(" ").to_s+"\n"
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
