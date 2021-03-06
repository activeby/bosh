# Copyright (c) 2003-2012 Active Cloud, Inc.

RSpec.configure do |config|
  config.before(:each) do
    Fog.mock!
    #Bosh::CloudStackCloud::Api.authorize({cloudstack_api_key: 'test', cloudstack_host: 'localhost'})
 end
  config.after(:each) do
    #Bosh::CloudStackCloud::Api.break_connection
    Fog::Mock.reset
  end
end

def empty_fog_response
  {'response' => {}}
end

def empty_fog_list_response
  {'listresponse' => {'count' => 0, 'values' => []}}
end
