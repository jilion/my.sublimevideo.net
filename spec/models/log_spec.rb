# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  name       :string(255)
#  hostname   :string(255)
#  state      :string(255)
#  file       :string(255)
#  started_at :datetime
#  ended_at   :datetime
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Log do
  
  describe "Class methods" do
    
    describe "delay_new_logs_download" do
      
      it "should call Log::Voxcast delay_new_logs_download" do
        Log::Voxcast.should_receive(:delay_new_logs_download)
        Log.delay_new_logs_download
      end
      
    end
    
  end
  
end