# coding: utf-8
require 'fast_spec_helper'
require 'validators/hostname_validator'
require 'support/shared_contexts/shared_contexts_for_hostname_validators'
require 'support/shared_examples/shared_examples_for_hostname_validators'

describe HostnameValidator do
  include_context 'setup for hostname validators', :hostname

  describe 'dev hostnames' do
    it_behaves_like 'valid hostnames', :hostname, 'école.fr'
    it_behaves_like 'invalid hostnames', :hostname, '*.google.com'
    it_behaves_like 'invalid hostnames', :hostname, '123.123.123'
  end

end
