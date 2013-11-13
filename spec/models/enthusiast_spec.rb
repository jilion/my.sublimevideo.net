require 'spec_helper'

describe Enthusiast do
  subject { create(:enthusiast) }

  context "with valid attributes" do
    describe '#email' do
      subject { super().email }
      it { should match /email\d+@enthusiast.com/ }
    end
    it { should be_valid }
  end

end

# == Schema Information
#
# Table name: enthusiasts
#
#  confirmation_resent_at :datetime
#  confirmation_sent_at   :datetime
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  created_at             :datetime
#  email                  :string(255)
#  free_text              :text
#  id                     :integer          not null, primary key
#  interested_in_beta     :boolean
#  invited_at             :datetime
#  remote_ip              :string(255)
#  starred                :boolean
#  trashed_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  index_enthusiasts_on_email  (email) UNIQUE
#

