Copyright (c) 2003-2012 Active Cloud, Inc.

cloudstack_cpi

# bundle exec rspec .

TODO:
0) Create console for testing purposes (analogue to AWS console in the aws/bin folder)
1) Add network support
2) Add stemcell support
3) Implement CPI class

# Network configuration
see https://github.com/cloudfoundry/oss-docs/blob/master/bosh/documentation/documentation.md#network-spec

# Registry
Initial settings for agent.
Ephemeral storage, as its name suggests, exists only as long as the instance it is associated with. If and when the user decides to delete the instance, the ephemeral storage is destroyed along with it. This is in contrast to persistent storage which remains in existence even if it is not currently being used by an instance. Persistent storage can thus be reused across instances and is priced separately while ephemeral storage is tied to each instance and is included in the instance charges.