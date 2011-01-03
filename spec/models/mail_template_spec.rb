require 'spec_helper'

describe MailTemplate do
  context "Factory" do
    before(:all) do
      @mail_template = Factory(:mail_template)
    end
    subject { @mail_template }
    
    its(:title)   { should =~ /Pricing survey \d+/ }
    its(:subject) { should == "{{user.full_name}} ({{user.email}}), help us shaping the right pricing" }
    its(:body)    { should == "Hi {{user.full_name}} ({{user.email}}), please respond to the survey, by clicking on the following <a href=\"http://survey.com\">link</a>" }
    
    it { should be_valid }
  end
  
  describe "Associations" do
    before(:all) do
      @mail_template = Factory(:mail_template)
    end
    subject { @mail_template }
    
    it { should have_many :logs }
  end
  
  describe "Validations" do
    [:title, :subject, :body].each do |attr|
      it { should allow_mass_assignment_of(attr) }
      it { should validate_presence_of(attr) }
    end
    
    it { should validate_uniqueness_of(:title) }
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

