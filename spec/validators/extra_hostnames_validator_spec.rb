# coding: utf-8
require 'fast_spec_helper'
require 'validators/extra_hostnames_validator'
require 'support/shared_contexts/shared_contexts_for_hostname_validators'
require 'support/shared_examples/shared_examples_for_hostname_validators'

describe ExtraHostnamesValidator do
  include_context 'setup for hostname validators', :extra_hostnames

  describe 'dev hostnames' do
    it_behaves_like 'valid hostnames', :extra_hostnames, 'blogspot.com, jilion.org'
    it_behaves_like 'invalid hostnames', :extra_hostnames, 'jilion.org, *.jilion.org'
    it_behaves_like 'invalid hostnames', :extra_hostnames, 'google.local, localhost'
    it_behaves_like 'invalid hostnames', :extra_hostnames, 'jilion.org, jilion.org'
  end

  describe 'extra hostnames that include hostname' do
    before { @site.hostname = 'jilion.org' }
    it_behaves_like 'invalid hostnames', :extra_hostnames, 'jilion.org'
  end

end
