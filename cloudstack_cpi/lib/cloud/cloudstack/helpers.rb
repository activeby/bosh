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

      ##
      # Raises CloudError exception
      #
      def cloud_error(message)
        if @logger
          @logger.error(message)
        end
        raise Bosh::Clouds::CloudError, message
      end

      # wait until resource will be put into the required state
      def wait_resource(resource, target_state, state_method = :status, timeout = DEFAULT_TIMEOUT)
        @logger.debug("Waiting for #{desc} to be #{target_state}") if @logger
        started_at = Time.now
        desc = resource.to_s

        loop do
          error_if_timed_out!(started_at, timeout, desc, target_state)

          state = resource.send(state_method)

          ensure_no_error_state!(desc, state, target_state)

          @logger.info("#{desc} has state #{state}.")
          break if state == target_state
          sleep(1)
        end

        if @logger
          total = Time.now - started_at
          @logger.info("#{desc} is now #{target_state}, took #{total}s")
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

