# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  state      :string(255)
#  file       :string(255)
#  started_at :datetime
#  ended_at   :datetime
#  size       :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Log do
  before(:each) { VCR.insert_cassette('logs') }
    
  # context "with valid attributes" do
  #   subject { Factory(:log) }
  #   
  #   it { subject.should be_unprocessed }
  #   it { subject.should be_valid }
  # end
  
  describe "Class Methods" do
    
    it "should download and save new logs" do
      # VCR.use_cassette('logs', :record => :new_episodes) do
        lambda { Log.download_and_save_new_logs }.should change(Log, :count).by(109)
      # end
    end
    
    # it "should download and only save news logs" do
    #   VCR.use_cassette('logs', :record => :new_episodes) do
    #     Factory(:log, :name => 'cdn.sublimevideo.net.log.1274001960-1274002020.gz')
    #     lambda { Log.download_and_save_new_logs }.should change(Log, :count).by(108)
    #   end
    # end
    
  end
  
  after(:each) { VCR.eject_cassette }
end
