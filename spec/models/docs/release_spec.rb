require 'spec_helper'

describe Docs::Release do

  describe "all" do
    subject { described_class.all(Rails.root.join("spec/fixtures/docs/releases"))}

    it { should have(2).releases }
  end

  describe "first release" do
    subject { described_class.all(Rails.root.join("spec/fixtures/docs/releases")).first }

    its(:datetime) { should == DateTime.parse('2010-12-20-13:30') }
  end

  describe "#atom_content" do
    subject { described_class.all(Rails.root.join("spec/fixtures/docs/releases")).first }

    it "should replace span and upcased label" do
      subject.atom_content.should include("[IMPROVED]")
      subject.atom_content.should include("[FIXED]")
    end
  end

end
