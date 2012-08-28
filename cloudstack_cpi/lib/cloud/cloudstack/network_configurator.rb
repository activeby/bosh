# Copyright (c) 2012 Active Technologies, Inc.

module Bosh::CloudStackCloud::NetworkOperations
      ##
      # Configures CloudStack server networking properties.
      #
      class NetworkConfigurator
        include Bosh::CloudStackCloud::OperationsHelpers

        def initialize(spec)
          unless spec.is_a?(Hash)
            raise ArgumentError, "Invalid spec, Hash expected, " \
                             "#{spec.class} provided"
          end

          @logger = Bosh::Clouds::Config.logger
          @dynamic_network = nil
          @vip_network = nil
          @security_groups = []

          spec.each_pair do |name, spec|
            network_type = spec["type"]
            network_type = "dynamic"

            case network_type
              when "dynamic"
                if @dynamic_network
                  cloud_error("More than one dynamic network for `#{name}'")
                else
                  @dynamic_network = DynamicNetwork.new(name, spec)
                  # only extract security groups for dynamic networks
                  extract_security_groups(spec)
                end
              when "vip"
                if @vip_network
                  cloud_error("More than one vip network for `#{name}'")
                else
                  @vip_network = VipNetwork.new(name, spec)
                end
              else
                cloud_error("Invalid network type `#{network_type}': CloudStack CPI " \
                      "can only handle `dynamic' and `vip' network types")
            end

          end

          #if @dynamic_network.nil?
          #  cloud_error("At least one dynamic network should be defined")
          #end

        end

        def configure(cloudstack, server)
          #@dynamic_network.configure(cloudstack, server)

          if @vip_network
            @vip_network.configure(cloudstack, server)
#          else
            # If there is no vip network we should disassociate any floating IP
            # currently held by server (as it might have had floating IP before)
#            show_methods_for_object(cloudstack)
#            addresses = cloudstack.addresses
#            addresses = cloudstack.list_public_ip_addresses
#            addresses.each do |address|
#              if address.instance_id == server.id
#                @logger.info("Disassociating floating IP `#{address.ip}' " \
#                         "from server `#{server.id}'")
#                address.server = nil
#              end
#            end
          end
        end

        ##
        # Returns the security groups for this network configuration, or
        # the default security groups if the configuration does not contain
        # security groups
        # @param [Array] default Default security groups
        # @return [Array] security groups
        def security_groups(default)
          if @security_groups.empty? && default
            return default
          else
            return @security_groups
          end
        end

        ##
        # Extracts the security groups from the network configuration
        # @param [Hash] network_spec Network specification
        # @raise [ArgumentError] if the security groups in the network_spec
        #   is not an Array
        def extract_security_groups(spec)
          if spec && spec["cloud_properties"]
            cloud_properties = spec["cloud_properties"]
            if cloud_properties && cloud_properties["security_groups"]
              unless cloud_properties["security_groups"].is_a?(Array)
                raise ArgumentError, "security groups must be an Array"
              end
              @security_groups += cloud_properties["security_groups"]
            end
          end
        end

      end
end
