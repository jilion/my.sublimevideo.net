# == Schema Information
#
# Table name: video_usages
#
#  id         :integer         not null, primary key
#  video_id   :integer
#  log_id     :integer
#  started_at :datetime
#  ended_at   :datetime
#  bandwidth  :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe VideoUsage do
  pending "add some examples to (or delete) #{__FILE__}"
end
