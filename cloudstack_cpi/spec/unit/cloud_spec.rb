# Copyright (c) 2003-2012 Active Cloud, Inc.

require 'spec_helper'

describe Bosh::CloudStackCloud::Cloud do
  context '#initialize' do
    let(:correct_parameters) do
      {
          'cloudstack' => {
              'cloudstack_api_key' => 'api_key',
              'cloudstack_secret_access_key' => 'secret_key',
              'cloudstack_host' => 'host',
          }
      }
    end

    def new_instance options
      Bosh::CloudStackCloud::Cloud.new options
    end

    it 'should receive configuration with cloudstack section' do
      expect { new_instance({}) }.to raise_error ArgumentError
    end

    def test_missing_parameters missing_param
      opt = correct_parameters
      opt['cloudstack'].delete missing_param

      expect { new_instance({}) }.to raise_error ArgumentError
    end

    it 'should receive cloudstack_api_key as a cloudstack configuration parameter' do
      test_missing_parameters 'cloudstack_api_key'
    end

    it 'should receive cloudstack_secret_access_key as a cloudstack configuration parameter' do
      test_missing_parameters 'cloudstack_secret_access_key'
    end

    it 'should receive cloudstack_host as a cloudstack configuration parameter' do
      test_missing_parameters 'cloudstack_host'
    end

    it 'should accept correct configuration' do
      new_instance(correct_parameters)
    end
  end
end