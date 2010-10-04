require 'spec_helper'

describe Mail::Template do
  subject { Factory(:mail_template) }
  
  context "with valid attributes" do
    its(:title)   { should == "Pricing survey" }
    its(:subject) { should == "Help us shaping the right pricing" }
    its(:body)    { should == "Hi {{user.full_name}}, please respond to the survey, by clicking on the following link:\nhttp://survey.com" }
    
    it { should be_valid }
  end
  
  describe "should be invalid" do
    it "without title" do
      mt = Factory.build(:mail_template, :title => nil)
      mt.should_not be_valid
      mt.errors[:title].should be_present
    end
    
    it "without subject" do
      ["", nil].each do |subject|
        mt = Factory.build(:mail_template, :subject => subject)
        mt.should_not be_valid
        mt.errors[:subject].should be_present
      end
    end
    
    it "without body" do
      ["", nil].each do |body|
        mt = Factory.build(:mail_template, :body => body)
        mt.should_not be_valid
        mt.errors[:body].should be_present
      end
    end
    
    it "without a unique title" do
      mt = Factory.build(:mail_template, :title => subject.title)
      mt.should_not be_valid
      mt.errors[:title].should be_present
    end
  end
  
end
# == Schema Information
#
# Table name: mail_templates
#
#  id         :integer         not null, primary key
#  title      :string(255)
#  subject    :string(255)
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#

