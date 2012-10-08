require 'fast_spec_helper'
require File.expand_path('lib/service/invoice')

Site = Struct.new(:params) unless defined?(Site)
AddonPlan = Class.new unless defined?(AddonPlan)

describe Service::Invoice do

  describe '.build_invoice' do
    it 'takes in account only visible billable items' do
      invoice = described_class.build_invoice(Time.now.previous_month).invoice

      invoice.invoice_items
    end
  end

end
