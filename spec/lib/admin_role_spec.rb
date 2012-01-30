require 'spec_helper'

describe AdminRole do

  describe ".roles" do
    it "has 3 roles for now" do
      described_class.roles.should eq %w[marcom player twitter invoices god]
    end
  end

end

describe AdminRoleMethods do

  class StubAdmin
    include AdminRoleMethods

    attr_accessor :roles

    def initialize(attributes)
      @roles = attributes[:roles]
    end
  end

  describe ".has_role?" do
    before(:each) do
      @admin_marcom   = StubAdmin.new(roles: ['marcom'])
      @admin_invoices = StubAdmin.new(roles: ['invoices'])
      @admin_god      = StubAdmin.new(roles: ['god'])
      @admin_multiple = StubAdmin.new(roles: ['marcom', 'invoices'])
      StubAdmin.included_modules.should include(AdminRoleMethods)
    end

    context "admin has marcom role" do
      it "#has_role?('marcom') is true" do
        @admin_marcom.has_role?('marcom').should be_true
      end

      it "#has_role?('invoices') is false" do
        @admin_marcom.has_role?('invoices').should be_false
      end

      it "#has_role?('god') is false" do
        @admin_marcom.has_role?('god').should be_false
      end
    end

    context "admin has invoices role" do
      it "#has_role?('invoices') is true" do
        @admin_invoices.has_role?('invoices').should be_true
      end

      it "#has_role?('marcom') is false" do
        @admin_invoices.has_role?('marcom').should be_false
      end

      it "#has_role?('god') is false" do
        @admin_invoices.has_role?('god').should be_false
      end
    end

    context "admin has god role" do
      it "#has_role?('god') is true" do
        @admin_god.has_role?('god').should be_true
      end

      it "#has_role?('marcom') is true" do
        @admin_god.has_role?('marcom').should be_true
      end

      it "#has_role?('invoices') is true" do
        @admin_god.has_role?('invoices').should be_true
      end
    end

    context "admin has 'marcom' and 'invoices' role" do
      it "#has_role?('marcom') is true" do
        @admin_multiple.has_role?('marcom').should be_true
      end

      it "#has_role?('invoices') is true" do
        @admin_multiple.has_role?('invoices').should be_true
      end

      it "#has_role?('god') is false" do
        @admin_multiple.has_role?('god').should be_false
      end
    end
  end

end