require 'spec_helper'

describe InvoicesHelper do

  pending "#invoice_items_grouped_by_site" do
    before(:all) do
      @user = Factory(:user)
      Timecop.travel(Time.utc(2010,2).beginning_of_month) do
        @site1 = Factory(:site, :user => @user, :hostname => "ccc.com", :activated_at => Time.now)
        @site2 = Factory(:site, :user => @user, :hostname => "bbb.com", :activated_at => Time.now)
      end
      @invoice = Invoice.build(:user => @user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month)
      @invoice.complete
    end

    it "should contain 2 sites with site2 in first position" do
      invoice_items_grouped_by_site = helper.invoice_items_grouped_by_site(@invoice)
      invoice_items_grouped_by_site[0][0].should == @site2
      invoice_items_grouped_by_site[1][0].should == @site1
    end

    it "should contain 2 sites with site2 in first position even if @site1 is updated" do
      with_versioning { @site1.reload.update_attributes(:hostname => "aaa.com") }
      @invoice = Invoice.find(@invoice.id) # hard reload
      invoice_items_grouped_by_site = helper.invoice_items_grouped_by_site(@invoice)
      invoice_items_grouped_by_site[0][0].should == @site2
      invoice_items_grouped_by_site[0][0].hostname.should == "bbb.com"
      invoice_items_grouped_by_site[1][0].should == @site1
      invoice_items_grouped_by_site[1][0].hostname.should == "ccc.com"
    end

  end

end
