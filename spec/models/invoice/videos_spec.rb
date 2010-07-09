require 'spec_helper'

describe Invoice::Videos do
  
  before(:all) do
    @user   = Factory(:user,
      :created_at => (1.months + 20.days).ago,
      :last_invoiced_on => 20.days.ago
    )
    @video1 = Factory(:video, :user => @user,
      :created_at              => 10.days.ago,
      :file_size               => 111111,
      :hits_cache              => 1000,
      :bandwidth_s3_cache      => 100000000,
      :bandwidth_us_cache      => 200000000,
      :bandwidth_eu_cache      => 150000000,
      :bandwidth_as_cache      => 50000000,
      :bandwidth_jp_cache      => 30000000,
      :bandwidth_unknown_cache => 10000000,
      :requests_s3_cache       => 100,
      :requests_us_cache       => 200,
      :requests_eu_cache       => 150,
      :requests_as_cache       => 50,
      :requests_jp_cache       => 30,
      :requests_unknown_cache  => 10
    )
    Factory(:video_encoding, :video => @video1,
      :started_encoding_at => 10.days.ago,
      :encoding_time       => 100,
      :file_size           => 1111,
      :file_added_at       => 10.days.ago,
      :file_removed_at     => 3.days.ago
    )
    Factory(:video_encoding, :video => @video1,
      :started_encoding_at => 3.days.ago,
      :encoding_time       => 101,
      :file_size           => 1112,
      :file_added_at       => 3.days.ago,
      :file_removed_at     => nil
    )
    @video2 = Factory(:video, :user => @user,
      :created_at              => 40.days.ago,
      :file_size               => 222222,
      :hits_cache              => 1001,
      :bandwidth_s3_cache      => 100000001,
      :bandwidth_us_cache      => 200000001,
      :bandwidth_eu_cache      => 150000001,
      :bandwidth_as_cache      => 50000001,
      :bandwidth_jp_cache      => 30000001,
      :bandwidth_unknown_cache => 10000001,
      :requests_s3_cache       => 101,
      :requests_us_cache       => 201,
      :requests_eu_cache       => 151,
      :requests_as_cache       => 51,
      :requests_jp_cache       => 31,
      :requests_unknown_cache  => 11
    )
    Factory(:video_encoding, :video => @video2,
      :started_encoding_at => 40.days.ago,
      :encoding_time       => 300,
      :file_size           => 2222,
      :file_added_at       => 40.days.ago,
      :file_removed_at     => 30.days.ago
    )
    Factory(:video_encoding, :video => @video2,
      :started_encoding_at => 30.days.ago,
      :encoding_time       => 301,
      :file_size           => 2223,
      :file_added_at       => 30.days.ago,
      :file_removed_at     => 5.days.ago
    )
    Factory(:video_encoding, :video => @video2,
      :started_encoding_at => 5.days.ago,
      :encoding_time       => 303,
      :file_size           => 2224,
      :file_added_at       => 5.days.ago,
      :file_removed_at     => nil
    )
    Factory(:video_encoding, :video => @video2,
      :started_encoding_at => 40.days.ago,
      :encoding_time       => 304,
      :file_size           => 2225,
      :file_added_at       => 40.days.ago,
      :file_removed_at     => nil
    )
  end
  after(:all) do
    User.delete_all
    Video.delete_all
    VideoUsage.delete_all
  end
  
  context "from cache" do
    let(:invoice) { Invoice.current(@user) }
    subject { invoice.videos }
    
    its(:bandwidth_upload)  { should == 111111 }
    its(:bandwidth_s3)      { should == 200000001 }
    its(:bandwidth_us)      { should == 400000001 }
    its(:bandwidth_eu)      { should == 300000001 }
    its(:bandwidth_as)      { should == 100000001 }
    its(:bandwidth_jp)      { should == 60000001 }
    its(:bandwidth_unknown) { should == 20000001 }
    its(:requests_s3)       { should == 201 }
    its(:requests_us)       { should == 401 }
    its(:requests_eu)       { should == 301 }
    its(:requests_as)       { should == 101 }
    its(:requests_jp)       { should == 61 }
    its(:requests_unknown)  { should == 21 }
    its(:encoding_time)     { should == 101 + 100 + 303 }
    its(:hits)              { should == 2001 }
    
    its(:storage_bytehrs)   { should ==
      (((3.days.ago - 10.day.ago) / 60**2).round * 1111) +
      (((invoice.ended_on.to_time - 3.days.ago) / 60**2).round * 1112) +
      (((5.days.ago - invoice.started_on.to_time) / 60**2).round * 2223) +
      (((invoice.ended_on.to_time - 5.days.ago) / 60**2).round * 2224) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 60**2).round * 2225)
    }
    
    # it "should return site array" do
    #   subject.should include(:id => @site2.id, :hostname => @site2.hostname, :archived_at => nil, :loader_amount => 50, :player_amount => 5, :loader_hits => 50, :player_hits => 5)
    #   subject.should include(:id => @site1.id, :hostname => @site1.hostname, :archived_at => nil, :loader_amount => 100, :player_amount => 11, :loader_hits => 100, :player_hits => 11)
    # end
  end
  
  # context "from logs" do
  #   
  #   before(:each) do
  #     @user  = Factory(:user, :trial_ended_at => 3.month.ago, :invoices_count => 1, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
  #     @site1 = Factory(:site, :user => @user)
  #     @site2 = Factory(:site, :user => @user, :hostname => "google.com")
  #     VCR.use_cassette('one_saved_logs') do
  #       @log = Factory(:log_voxcast, :started_at => 1.month.ago, :ended_at => 1.month.ago + 3.days)
  #     end
  #     Factory(:site_usage, :site => @site1, :log => @log, :loader_hits => 1000100, :player_hits => 15)
  #     Factory(:site_usage, :site => @site2, :log => @log, :loader_hits => 53, :player_hits => 7)
  #     invoice = Factory(:invoice, :user => @user)
  #     @invoice = Invoice.find(invoice)# problem if not reloaded, but don't fucking know why!
  #   end
  #   
  #   subject { Invoice::Sites.new(@invoice) }
  #   
  #   its(:amount)        { should == 1000175 }
  #   its(:loader_amount) { should == 1000153 }
  #   its(:player_amount) { should == 22 }
  #   its(:loader_hits)   { should == 1000153 }
  #   its(:player_hits)   { should == 22 }
  #   it "should return site array" do
  #     subject.should include(:id => @site1.id, :hostname => @site1.hostname, :archived_at => nil, :loader_amount => 1000100, :player_amount => 15, :loader_hits => 1000100, :player_hits => 15)
  #     subject.should include(:id => @site2.id, :hostname => @site2.hostname, :archived_at => nil, :loader_amount => 53, :player_amount => 7, :loader_hits => 53, :player_hits => 7)
  #   end
  # end
  
end