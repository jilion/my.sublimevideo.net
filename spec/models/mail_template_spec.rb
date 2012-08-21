require 'spec_helper'

describe MailTemplate do

  context "Factory" do
    subject { create(:mail_template) }

    its(:title)   { should =~ /Pricing survey \d+/ }
    its(:subject) { should include "{{user.name}} ({{user.email}}), help us shaping the right pricing" }
    its(:body)    { should include "Hi {{user.name}} ({{user.email}}), please respond to the survey, by clicking on the following url: http://survey.com" }

    it { should be_valid }
  end

  describe "Associations" do
    subject { create(:mail_template) }

    it { should have_many :logs }
  end

  describe "Validations" do
    [:title, :subject, :body].each do |attr|
      it { should allow_mass_assignment_of(attr) }
      it { should validate_presence_of(attr) }
    end

    context "with an already mail template" do
      before { create(:mail_template) }

      it { should validate_uniqueness_of(:title) }
    end
  end

end

# == Schema Information
#
# Table name: mail_templates
#
#  body       :text
#  created_at :datetime
#  id         :integer          not null, primary key
#  subject    :string(255)
#  title      :string(255)
#  updated_at :datetime
#

