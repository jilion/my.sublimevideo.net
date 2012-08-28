require 'fast_spec_helper'
require File.expand_path('lib/admin_role')

describe AdminRole do

  describe ".roles" do
    it "has 3 roles for now" do
      described_class.roles.should eq %w[marcom player twitter invoices god]
    end
  end

end
