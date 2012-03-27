require 'spec_helper'

describe Enthusiast do
  subject { create(:enthusiast) }

  context "with valid attributes" do
    its(:email) { should match /email\d+@enthusiast.com/ }
    it { should be_valid }
  end

end
# == Schema Information
#
# Table name: enthusiasts
#
#  id                     :integer         not null, primary key
#  email                  :string(255)
#  free_text              :text
#  interested_in_beta     :boolean
#  remote_ip              :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  trashed_at             :datetime
#  created_at             :datetime
#  updated_at             :datetime
#  invited_at             :datetime
#  starred                :boolean
#  confirmation_resent_at :datetime
#
# Indexes
#
#  index_enthusiasts_on_email  (email) UNIQUE
#

