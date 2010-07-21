require 'spec_helper'

describe Invoice::Videos do
  
  context "from cache" do
    before(:each) do
      @user   = Factory(:user,
        :created_at => (1.months + 20.days).ago,
        :last_invoiced_on => 20.days.ago,
        :next_invoiced_on => 10.days.from_now
      )
      create_videos_with_encoding_for(@user)
    end
    
    let(:invoice) { Invoice.current(@user) }
    subject { invoice.videos }
    
    its(:bandwidth_upload)         { should == 111111 }
    its(:bandwidth_s3)             { should == 200000001 }
    its(:bandwidth_us)             { should == 400000001 }
    its(:bandwidth_eu)             { should == 300000001 }
    its(:bandwidth_as)             { should == 100000001 }
    its(:bandwidth_jp)             { should == 60000001 }
    its(:bandwidth_unknown)        { should == 20000001 }
    its(:requests_s3)              { should == 201 }
    its(:requests_us)              { should == 401 }
    its(:requests_eu)              { should == 301 }
    its(:requests_as)              { should == 101 }
    its(:requests_jp)              { should == 61 }
    its(:requests_unknown)         { should == 21 }
    its(:encoding_time)            { should == 101 + 100 + 303 }
    its(:hits)                     { should == 2001 }
    its(:storage_bytehrs)          { should ==
      (((invoice.ended_on.to_time - 10.days.ago) / 60**2).round * 111111) +
      (((3.days.ago - 10.day.ago) / 60**2).round * 1111) +
      (((invoice.ended_on.to_time - 3.days.ago) / 60**2).round * 1112) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 60**2).round * 222222) +
      (((5.days.ago - invoice.started_on.to_time) / 60**2).round * 2223) +
      (((invoice.ended_on.to_time - 5.days.ago) / 60**2).round * 2224) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 60**2).round * 2225)
    }
    its(:bandwidth_upload_amount)  { should == 1 }
    its(:bandwidth_s3_amount)      { should == 2000 }
    its(:bandwidth_us_amount)      { should == 4000 }
    its(:bandwidth_eu_amount)      { should == 3000 }
    its(:bandwidth_as_amount)      { should == 1000 }
    its(:bandwidth_jp_amount)      { should == 600 }
    its(:bandwidth_unknown_amount) { should == 200 }
    its(:bandwidth_amount)         { should == 10801 }
    its(:requests_s3_amount)       { should == 0 }
    its(:requests_us_amount)       { should == 0 }
    its(:requests_eu_amount)       { should == 0 }
    its(:requests_as_amount)       { should == 0 }
    its(:requests_jp_amount)       { should == 0 }
    its(:requests_unknown_amount)  { should == 21 }
    its(:requests_amount)          { should == 21 }
    its(:storage_amount)           { should satisfy { |a| [215,216].include?(a) } } # depends on time
    its(:encoding_amount)          { should == 504 }
    its(:amount)                   { should satisfy { |a| [11541,11542].include?(a) } } # depends on time
    
    it "should return video array" do
      videos_ids = subject.collect { |video| video[:id] }
      videos_ids.should include(@video1.id)
      videos_ids.should include(@video2.id)
    end
  end
  
  context "from logs" do
    before(:each) do
      @user   = Factory(:user,
        :created_at => (2.month + 1.day).ago,
        :invoices_count => 1,
        :last_invoiced_on => (1.month + 1.day).ago,
        :next_invoiced_on => 1.day.ago
      )
      create_videos_with_encoding_for(@user)
      log = Factory(:log_cloudfront_download, :started_at => 1.month.ago, :ended_at => 1.month.ago + 3.days)
      Factory(:video_usage, :video => @video1, :log => log,
        :hits              => 1000,
        :bandwidth_s3      => 100000000,
        :bandwidth_us      => 200000000,
        :bandwidth_eu      => 150000000,
        :bandwidth_as      => 50000000,
        :bandwidth_jp      => 30000000,
        :bandwidth_unknown => 10000000,
        :requests_s3       => 100,
        :requests_us       => 200,
        :requests_eu       => 150,
        :requests_as       => 50,
        :requests_jp       => 30,
        :requests_unknown  => 10
      )
      Factory(:video_usage, :video => @video1, :log => log,
        :hits              => 100,
        :bandwidth_s3      => 10000000,
        :bandwidth_us      => 20000000,
        :bandwidth_eu      => 15000000,
        :bandwidth_as      => 5000000,
        :bandwidth_jp      => 3000000,
        :bandwidth_unknown => 1000000,
        :requests_s3       => 10,
        :requests_us       => 20,
        :requests_eu       => 15,
        :requests_as       => 5,
        :requests_jp       => 3,
        :requests_unknown  => 1
      )
      Factory(:video_usage, :video => @video2, :log => log,
        :hits              => 1001,
        :bandwidth_s3      => 100000001,
        :bandwidth_us      => 200000001,
        :bandwidth_eu      => 150000001,
        :bandwidth_as      => 50000001,
        :bandwidth_jp      => 30000001,
        :bandwidth_unknown => 10000001,
        :requests_s3       => 101,
        :requests_us       => 201,
        :requests_eu       => 151,
        :requests_as       => 51,
        :requests_jp       => 31,
        :requests_unknown  => 11
      )
      
      @invoice = Factory(:invoice, :user => @user)
    end
    
    let(:invoice) { Invoice.find(@invoice) } # must be deep reloaded!
    subject { Invoice::Videos.new(invoice) }
    
    its(:bandwidth_upload)         { should == 111111 }
    its(:bandwidth_s3)             { should == 210000001 }
    its(:bandwidth_us)             { should == 420000001 }
    its(:bandwidth_eu)             { should == 315000001 }
    its(:bandwidth_as)             { should == 105000001 }
    its(:bandwidth_jp)             { should == 63000001 }
    its(:bandwidth_unknown)        { should == 21000001 }
    its(:requests_s3)              { should == 211 }
    its(:requests_us)              { should == 421 }
    its(:requests_eu)              { should == 316 }
    its(:requests_as)              { should == 106 }
    its(:requests_jp)              { should == 64 }
    its(:requests_unknown)         { should == 22 }
    its(:encoding_time)            { should == 101 + 100 + 301 + 303 }
    its(:hits)                     { should == 2101 }
    its(:storage_bytehrs)          { should ==
      (((invoice.ended_on.to_time - 10.days.ago) / 60**2).round * 111111) +
      (((3.days.ago - 10.day.ago) / 60**2).round * 1111) +
      (((invoice.ended_on.to_time - 3.days.ago) / 60**2).round * 1112) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 60**2).round * 222222) +
      (((30.days.ago - invoice.started_on.to_time) / 60**2).round * 2222) +
      (((5.days.ago - 30.days.ago) / 60**2).round * 2223) +
      (((invoice.ended_on.to_time - 5.days.ago) / 60**2).round * 2224) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 60**2).round * 2225)
    }
    its(:bandwidth_upload_amount)  { should == 1 }
    its(:bandwidth_s3_amount)      { should == 2100 }
    its(:bandwidth_us_amount)      { should == 4200 }
    its(:bandwidth_eu_amount)      { should == 3150 }
    its(:bandwidth_as_amount)      { should == 1050 }
    its(:bandwidth_jp_amount)      { should == 630 }
    its(:bandwidth_unknown_amount) { should == 210 }
    its(:bandwidth_amount)         { should == 11341 }
    its(:requests_s3_amount)       { should == 0 }
    its(:requests_us_amount)       { should == 0 }
    its(:requests_eu_amount)       { should == 0 }
    its(:requests_as_amount)       { should == 0 }
    its(:requests_jp_amount)       { should == 0 }
    its(:requests_unknown_amount)  { should == 22 }
    its(:requests_amount)          { should == 22 }
    its(:storage_amount)           { should satisfy { |a| (185..187).include?(a) } } # depends on time
    its(:encoding_amount)          { should == 805 }
    its(:amount)                   { should satisfy { |a| (12353..12355).include?(a) } } # depends on time
    
    it "should return video array" do
      videos_ids = subject.collect { |video| video[:id] }
      videos_ids.should include(@video1.id)
      videos_ids.should include(@video2.id)
    end
  end
  
private
  
  def create_videos_with_encoding_for(user)
    @video1 = Factory(:video, :user => user,
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
    Factory(:video_encoding, :video => @video1,
      :started_encoding_at => 20.days.from_now,
      :encoding_time       => 102,
      :file_size           => 1113,
      :file_added_at       => 20.days.from_now,
      :file_removed_at     => nil
    )
    @video2 = Factory(:video, :user => user,
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
  
end