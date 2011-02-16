require 'spec_helper'

describe SiteObserver do
  
  describe "site plans lifetimes" do
    let(:plan1) { Factory(:plan) }
    let(:plan2) { Factory(:plan) }
    let(:site)  { Factory(:site, :plan_id => plan1.id) }
    
    specify { lambda { site }.should change(Lifetime, :count).by(1) }
    
    describe "when a site is created" do
      before(:all) do
        Timecop.freeze(Time.utc(2010,1,1)) { @site = site }
      end
      subject { @site.lifetimes.order(:created_at).first  }
      
      it { should belong_to_site(@site).the_item(plan1).of_type("Plan").created_at(Time.utc(2010,1,1)).and_deleted_at(nil) }
    end
    
    context "with already a site created" do
      specify { lambda { site.reload.update_attributes(:plan_id => plan2.id) }.should change(Lifetime, :count).by(1+1) }
      
      describe "when updated once" do
        before(:all) do
          Timecop.freeze(Time.utc(2010,1,1)) { @site = site }
          Timecop.freeze(Time.utc(2010,2,2)) { @site.reload.update_attributes(:plan_id => plan2.id) }
        end
        
        describe "first lifetime" do
          subject { @site.lifetimes.order(:created_at).first  }
          
          it { should belong_to_site(@site).the_item(plan1).of_type("Plan").created_at(Time.utc(2010,1,1)).and_deleted_at(Time.utc(2010,2,2)) }
        end
        describe "second lifetime" do
          subject { @site.lifetimes.order(:created_at).second }
          
          it { should belong_to_site(@site).the_item(plan2).of_type("Plan").created_at(Time.utc(2010,2,2)).and_deleted_at(nil) }
        end
      end
      
      describe "when updated twice" do
        before(:all) do
          Timecop.freeze(Time.utc(2010,1,1)) { @site = site }
          Timecop.freeze(Time.utc(2010,2,2)) { @site.reload.update_attributes(:plan_id => plan2.id) }
          Timecop.freeze(Time.utc(2010,3,3)) { @site.reload.update_attributes(:plan_id => plan1.id) }
        end
        
        describe "first lifetime" do
          subject { @site.lifetimes.order(:created_at).first  }
          
          it { should belong_to_site(@site).the_item(plan1).of_type("Plan").created_at(Time.utc(2010,1,1)).and_deleted_at(Time.utc(2010,2,2)) }
        end
        describe "second lifetime" do
          subject { @site.lifetimes.order(:created_at).second }
          
          it { should belong_to_site(@site).the_item(plan2).of_type("Plan").created_at(Time.utc(2010,2,2)).and_deleted_at(Time.utc(2010,3,3)) }
        end
        describe "third lifetime" do
          subject { @site.lifetimes.order(:created_at).third }
          
          it { should belong_to_site(@site).the_item(plan1).of_type("Plan").created_at(Time.utc(2010,3,3)).and_deleted_at(nil) }
        end
      end
    end
  end

end

RSpec::Matchers.define :belong_to_site do |site|
  match do |actual|
    actual.site == site && actual.item == @item && actual.item_type == @item_type \
    && actual.created_at == @creation_date && actual.deleted_at == @deletion_date
  end
  
  chain :the_item do |item|
    @item = item
  end
  chain :of_type do |item_type|
    @item_type = item_type
  end
  chain :created_at do |creation_date|
    @creation_date = creation_date
  end
  chain :deleted_at do |deletion_date|
    @deletion_date = deletion_date
  end
  chain :and_deleted_at do |deletion_date|
    @deletion_date = deletion_date
  end
  
  diffable
end