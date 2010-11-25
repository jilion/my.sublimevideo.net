require 'spec_helper'

describe SiteObserver do
  
  describe "site plans lifetimes" do
    let(:plan1) { Factory(:plan) }
    let(:plan2) { Factory(:plan) }
    let(:site)  { Factory(:site, :plan_id => plan1.id) }
    specify { lambda { site }.should change(Lifetime, :count).by(1) }
    
    describe "when a site is created, lifetime" do
      before(:all) { @site = site }
      subject { @site.lifetimes.order(:created_at).first  }
      
      its(:site)       { should == @site }
      its(:item)       { should == plan1 }
      its(:item_type)  { should == "Plan" }
      its(:created_at) { should == @site.updated_at }
      its(:deleted_at) { should be_nil }
    end
    
    context "with already a site created," do
      specify { lambda { site.reload.update_attributes(:plan_id => plan2.id) }.should change(Lifetime, :count).by(1+1) }
      
      describe "when updated," do
        before(:all) do
          @site = site
          @first_updated_at = @site.reload.updated_at
          site.update_attributes(:plan_id => plan2.id)
          @second_updated_at = @site.reload.updated_at
        end
        describe "first lifetime" do
          subject { @site.lifetimes.order(:created_at).first  }
          
          its(:site)       { should == @site }
          its(:item)       { should == plan1 }
          its(:item_type)  { should == "Plan" }
          its(:created_at) { should == @first_updated_at }
          its(:deleted_at) { should == @second_updated_at }
        end
        describe "second lifetime" do
          subject { @site.lifetimes.order(:created_at).second }
          
          its(:site)       { should == @site }
          its(:item)       { should == plan2 }
          its(:item_type)  { should == "Plan" }
          its(:created_at) { should == @second_updated_at }
          its(:deleted_at) { should be_nil }
        end
      end
      describe "when updated twice," do
        before(:all) do
          @site = site
          @first_updated_at = @site.reload.updated_at
          @site.update_attributes(:plan_id => plan2.id)
          @second_updated_at = @site.reload.updated_at
          @site.update_attributes(:plan_id => plan1.id)
          @third_updated_at = @site.reload.updated_at
        end
        describe "first lifetime" do
          subject { @site.lifetimes.order(:created_at).first  }
          
          its(:site)       { should == @site }
          its(:item)       { should == plan1 }
          its(:item_type)  { should == "Plan" }
          its(:created_at) { should == @first_updated_at }
          its(:deleted_at) { should == @second_updated_at }
        end
        describe "second lifetime" do
          subject { @site.lifetimes.order(:created_at).second }
          
          its(:site)       { should == @site }
          its(:item)       { should == plan2 }
          its(:item_type)  { should == "Plan" }
          its(:created_at) { should == @second_updated_at }
          its(:deleted_at) { should == @third_updated_at }
        end
        describe "third lifetime" do
          subject { @site.lifetimes.order(:created_at).third }
          
          its(:site)       { should == @site }
          its(:item)       { should == plan1 }
          its(:item_type)  { should == "Plan" }
          its(:created_at) { should == @third_updated_at }
          its(:deleted_at) { should be_nil }
        end
      end
      
    end
  end
  
  describe "site addons lifetimes" do
    let(:addon1) { Factory(:addon) }
    let(:addon2) { Factory(:addon) }
    let(:addon3) { Factory(:addon) }
    let(:site)   { Factory(:site, :addon_ids => [addon1.id, addon2.id]) }
    specify { lambda { site }.should change(Lifetime, :count).by(1+2) }
    
    describe "when a site is created with two addons" do
      before(:all) { @site = site }
      describe "addon1 lifetime" do
        subject { @site.lifetimes.where(:item_id => addon1.id).order(:created_at).first }
        
        its(:site)       { should == @site }
        its(:item)       { should == addon1 }
        its(:item_type)  { should == "Addon" }
        its(:created_at) { should == @site.updated_at }
        its(:deleted_at) { should be_nil }
      end
      describe "addon2 lifetime" do
        subject { @site.lifetimes.where(:item_id => addon2.id).order(:created_at).first }
        
        its(:site)       { should == @site }
        its(:item)       { should == addon2 }
        its(:item_type)  { should == "Addon" }
        its(:created_at) { should == @site.updated_at }
        its(:deleted_at) { should be_nil }
      end
    end
    
    context "with already a site created," do
      specify { lambda { site.reload.update_attributes(:addon_ids => [addon2.id, addon3.id]) }.should change(Lifetime, :count).by(3+1) }
      
      describe "when updated with one more and one less," do
        before(:all) do
          @site = site
          @first_updated_at = @site.reload.updated_at
          @site.update_attributes(:addon_ids => [addon2.id, addon3.id])
          @second_updated_at = @site.reload.updated_at
        end
        describe "addon1 lifetime" do
          subject { @site.lifetimes.where(:item_id => addon1.id).order(:created_at).first }
          
          its(:site)       { should == @site }
          its(:item)       { should == addon1 }
          its(:item_type)  { should == "Addon" }
          its(:created_at) { should == @first_updated_at }
          its(:deleted_at) { should == @second_updated_at }
        end
        describe "addon2 lifetime" do
          subject { @site.lifetimes.where(:item_id => addon2.id).order(:created_at).first }
          
          its(:site)       { should == @site }
          its(:item)       { should == addon2 }
          its(:item_type)  { should == "Addon" }
          its(:created_at) { should == @first_updated_at }
          its(:deleted_at) { should be_nil }
        end
        describe "addon3 lifetime" do
          subject { @site.lifetimes.where(:item_id => addon3.id).order(:created_at).first }
          
          its(:site)       { should == @site }
          its(:item)       { should == addon3 }
          its(:item_type)  { should == "Addon" }
          its(:created_at) { should == @second_updated_at }
          its(:deleted_at) { should be_nil }
        end
      end
      describe "when updated twice," do
        before(:all) do
          @site = site
          @first_updated_at = @site.reload.updated_at
          @site.update_attributes(:addon_ids => [addon2.id, addon3.id])
          @second_updated_at = @site.reload.updated_at
          @site.update_attributes(:addon_ids => [addon1.id])
          @third_updated_at = @site.reload.updated_at
        end
        describe "addon1 lifetime first" do
          subject { @site.lifetimes.where(:item_id => addon1.id).order(:created_at).first }
          
          its(:site)       { should == @site }
          its(:item)       { should == addon1 }
          its(:item_type)  { should == "Addon" }
          its(:created_at) { should == @first_updated_at }
          its(:deleted_at) { should == @second_updated_at }
        end
        describe "addon1 lifetime second" do
          subject { @site.lifetimes.where(:item_id => addon1.id).order(:created_at).second }
          
          its(:site)       { should == @site }
          its(:item)       { should == addon1 }
          its(:item_type)  { should == "Addon" }
          its(:created_at) { should == @third_updated_at }
          its(:deleted_at) { should be_nil }
        end
        describe "addon2 lifetime" do
          subject { @site.lifetimes.where(:item_id => addon2.id).order(:created_at).first }
          
          its(:site)       { should == @site }
          its(:item)       { should == addon2 }
          its(:item_type)  { should == "Addon" }
          its(:created_at) { should == @first_updated_at }
          its(:deleted_at) { should == @third_updated_at }
        end
        describe "addon3 lifetime" do
          subject { @site.lifetimes.where(:item_id => addon3.id).order(:created_at).first }
          
          its(:site)       { should == @site }
          its(:item)       { should == addon3 }
          its(:item_type)  { should == "Addon" }
          its(:created_at) { should == @second_updated_at }
          its(:deleted_at) { should == @third_updated_at }
        end
      end
      
    end
  end
  
end
