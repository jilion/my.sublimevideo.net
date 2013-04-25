# coding: utf-8
require 'fast_spec_helper'
require 'validators/dev_hostnames_validator'
require 'support/shared_contexts/shared_contexts_for_hostname_validators'
require 'support/shared_examples/shared_examples_for_hostname_validators'

describe DevHostnamesValidator do
  include_context 'setup for hostname validators', :dev_hostnames

  describe 'dev hostnames' do
    it_behaves_like 'valid hostnames', :dev_hostnames, 'localhost, 127.0.0.1'
    it_behaves_like 'invalid hostnames', :dev_hostnames, 'localhost, *.local'
    it_behaves_like 'invalid hostnames', :dev_hostnames, '124.123.151.123, localhost'
    it_behaves_like 'invalid hostnames', :dev_hostnames, 'localhost, localhost'
  end

  describe 'dev hostnames that include hostname' do
    before { @site.hostname = 'remy.local' }
    it_behaves_like 'invalid hostnames', :dev_hostnames, 'remy.local'
  end

end
