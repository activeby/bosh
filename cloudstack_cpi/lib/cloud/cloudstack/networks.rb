# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh::CloudStackCloud::NetworkOperations
  ##
  #
  class DynamicNetwork
    def configure(cloudstack, server)
      # dynamic networks are completely managed by CloudStack
    end
  end

  class ManualNetwork
    include Bosh::CloudStackCloud::OperationsHelpers
    ## if method to be supported
    # @ip = spec["ip"] # use ip for manual config and other network properties

    def configure(cloudstack, server)
      cloud_error("manual network configuration is not supported by CloudStack CPI")
    end
  end

  class VipNetwork
    include Bosh::CloudStackCloud::OperationsHelpers

    ##
    # Creates a new network
    #
    # @param [String] name Network name
    # @param [Hash] spec Raw network spec
    def initialize(name, spec)
      unless spec.is_a?(Hash)
        raise ArgumentError, "Invalid spec, Hash expected, " \
                             "#{spec.class} provided"
      end

      @logger = Bosh::Clouds::Config.logger

      @name = name
      @cloud_properties = spec["cloud_properties"]
      @public_ip = spec["cloud_properties"]["public_ip"]
      @public_port = spec["cloud_properties"]["public_port"]
      ## the port range can be supported
      # @public_start_port = spec["cloud_properties"]["public_start_port"]
      # @public_end_port = spec["cloud_properties"]["public_end_port"]
      # @private_port = spec["cloud_properties"]["private_port"]
      # @private_start_port = spec["cloud_properties"]["private_start_port"]
      # @private_end_port = spec["cloud_properties"]["private_end_port"]
    end

    ##
    # Configures vip network
    #
    # @param [Fog::Compute::CloudStack] cloudstack Fog CloudStack Compute client
    # @param [Fog::Compute::CloudStack::Server] server CloudStack server to configure
    def configure(cloudstack, server)
      if @public_ip.nil?
        cloud_error("No public_ip provided for vip network `#{@name}'")
      end
      if @public_port.nil?
        cloud_error("No public_port provided for vip network `#{@name}'")
      end

      @logger.info("Associating server `#{server.id}' " \
                   "with public IP `#{@public_ip}'" \
                   "and using port forwarding for ports `#{@public_port}'")

      ipaddress_properties = cloudstack.list_public_ip_addresses("ipaddress"=>"#{@public_ip}")\
                                                        ["listpublicipaddressesresponse"]["publicipaddress"].first
      ipaddressid = ipaddress_properties["id"]
      cloudstack.create_port_forwarding_rule("ipaddressid"=>ipaddressid, "publicport"=>@public_port,\
                                "protocol"=>"tcp", "privateport"=>@public_port, "virtualmachineid"=>"#{server.id}")
    end

  end

end