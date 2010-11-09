require 'spec_helper'

describe MailTemplate do
  context "from factory" do
    set(:mail_template_from_factory) { Factory(:mail_template) }
    subject { mail_template_from_factory }
    
    its(:title)   { should =~ /Pricing survey \d+/ }
    its(:subject) { should == "{{user.full_name}} ({{user.email}}), help us shaping the right pricing" }
    its(:body)    { should == "Hi {{user.full_name}} ({{user.email}}), please respond to the survey, by clicking on the following link:\nhttp://survey.com" }
    
    it { should be_valid }
  end
  
  describe "associations" do
    set(:mail_template_for_associations) { Factory(:mail_template) }
    subject { mail_template_for_associations }
    
    it { should have_many :logs }
  end
  
  describe "validates" do
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

