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
    %w[title subject body].each do |attribute|
      it "without #{attribute}" do
        mt = Factory.build(:mail_template, attribute.to_sym => nil)
        mt.should_not be_valid
        mt.errors[attribute.to_sym].should be_present
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

