require 'spec_helper'

describe Release do
  
  describe "all" do
    subject { Release.all(Rails.root.join("spec/fixtures/releases"))}
    
    it { should have(2).releases }
  end
  
  describe "first release" do
    subject { Release.all(Rails.root.join("spec/fixtures/releases")).first }
    
    its(:datetime) { should == DateTime.parse('2010-12-20-13:30') }
  end
  
  describe "#atom_content" do
    subject { Release.all(Rails.root.join("spec/fixtures/releases")).first }
    
    it "should replace span and upcased label" do
      subject.atom_content.should include("[IMPROVED]")
      subject.atom_content.should include("[FIXED]")
    end
  end
  
end
