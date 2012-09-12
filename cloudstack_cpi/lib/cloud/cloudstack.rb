# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh
  module CloudStackCloud; end
end

require 'fog'
require "httpclient"
require "pp"
require "set"
require "tmpdir"
require "uuidtools"
require "yajl"
require "base64"

require "common/thread_pool"
require "common/thread_formatter"


require "cloud"
require "cloud/cloudstack/operations_helpers"
require "cloud/cloudstack/registry_operations"
require "cloud/cloudstack/registry_client"
require "cloud/cloudstack/stemcell_operations"
require "cloud/cloudstack/disk_operations"
require "cloud/cloudstack/vm_operations"
require "cloud/cloudstack/deployment_validation"
require "cloud/cloudstack/network_operations"
require "cloud/cloudstack/network_configurator"
require "cloud/cloudstack/networks"
require "cloud/cloudstack/cloud"
module Bosh
  module Clouds
    CloudStack = Bosh::CloudStackCloud::Cloud
    Cloudstack = CloudStack # Alias needed for Bosh::Clouds::Provider.create method
  end
end
