# == Schema Information
#
# Table name: video_profile_versions
#
#  id               :integer         not null, primary key
#  video_profile_id :integer
#  panda_profile_id :string(255)
#  note             :text
#  num              :integer
#  created_at       :datetime
#  updated_at       :datetime
#

require 'spec_helper'

describe VideoProfileVersion do
  pending "add some examples to (or delete) #{__FILE__}"
end
