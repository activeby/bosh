module Bosh
  module CloudStackCloud; end
end

# require "httpclient"
require "pp"
require "set"
require "tmpdir"
require "uuidtools"
# require "yajl"

require "common/thread_pool"
require "common/thread_formatter"


require "cloud"
require "cloud/cloudstack/stemcell_operations"
require "cloud/cloudstack/disk_operations"
require "cloud/cloudstack/vm_operations"
require "cloud/cloudstack/deployment_validation"
require "cloud/cloudstack/network_configuration"
require "cloud/cloudstack/helpers"
require "cloud/cloudstack/cloud"
module Bosh
  module Clouds
    CloudStack = Bosh::CloudStackCloud::Cloud
  end
end
