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
    
    describe "delay_fetch_and_create_new_logs" do
      
      it "should call Log::Voxcast delay_fetch_download_and_create_new_logs" do
        Log::Voxcast.should_receive(:delay_fetch_download_and_create_new_logs)
        Log.delay_fetch_and_create_new_logs
      end
      
      it "should call Log::CloudfrontDownload delay_fetch_and_create_new_logs" do
        Log::CloudfrontDownload.should_receive(:delay_fetch_and_create_new_logs)
        Log.delay_fetch_and_create_new_logs
      end
      
    end
    
  end
  
end