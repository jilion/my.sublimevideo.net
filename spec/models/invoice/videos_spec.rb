require 'spec_helper'

describe Invoice::Videos do
  
  context "from cache" do
    before(:each) do
      @user = Factory(:user,
        :created_at => (1.months + 20.days).ago,
        :last_invoiced_on => 20.days.ago,
        :next_invoiced_on => 10.days.from_now
      )
      create_videos_with_encoding_for(@user)
      
    end
    
    let(:total_traffic)  { 200000001 + 400000001 + 300000001 + 100000001 + 60000001 + 20000001 + 111111 }
    let(:total_requests) { 201 + 401 + 301 + 101 + 61 + 21 }
    let(:total_storage)  do
      (((invoice.ended_on.to_time - 10.days.ago) / 1.hour).round * 111111) +
      (((3.days.ago - 10.day.ago) / 1.hour).round * 1111) +
      (((invoice.ended_on.to_time - 3.days.ago) / 1.hour).round * 1112) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 1.hour).round * 222222) +
      (((5.days.ago - invoice.started_on.to_time) / 1.hour).round * 2223) +
      (((invoice.ended_on.to_time - 5.days.ago) / 1.hour).round * 2224) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 1.hour).round * 2225)
    end
    let(:total_encoding_time) { 100 + 101 + 303 }
    let(:invoice) { Invoice.current(@user) }
    subject { invoice.videos }
    
    its(:hits)            { should == 2001 }
    its(:traffic_amount)  { should == (total_traffic.to_f / 1.gigabyte) * Prices.video(:one_GB_of_traffic) }
    its(:storage_amount)  { should == (total_storage.to_f / 1.gigabyte) * Prices.video(:one_GB_per_hour_storage) }
    its(:requests_amount) { should == (total_requests.to_f / 10000) * Prices.video(:ten_thousand_requests) }
    its(:encoding_amount) { should == total_encoding_time * Prices.video(:one_second_of_encoding) }
    its(:amount)          { should == (((total_traffic.to_f / 1.gigabyte) * Prices.video(:one_GB_of_traffic)) +
                                      ((total_storage.to_f / 1.gigabyte) * Prices.video(:one_GB_per_hour_storage)) +
                                      ((total_requests.to_f / 10000) * Prices.video(:ten_thousand_requests)) +
                                      (total_encoding_time * Prices.video(:one_second_of_encoding))).round }
    
    it "should return video array" do
      videos_ids = subject.collect { |video| video[:id] }
      videos_ids.should include(@video1.id)
      videos_ids.should include(@video2.id)
    end
  end
  
  context "from logs" do
    before(:each) do
      @user = Factory(:user,
        :created_at => (2.month + 1.day).ago,
        :invoices_count => 1,
        :last_invoiced_on => (1.month + 1.day).ago,
        :next_invoiced_on => 1.day.ago
      )
      create_videos_with_encoding_for(@user)
      log = Factory(:log_cloudfront_download, :started_at => 1.month.ago, :ended_at => 1.month.ago + 3.days)
      Factory(:video_usage, :video => @video1, :log => log,
        :hits             => 1000,
        :traffic_s3       => 100000000,
        :traffic_us       => 200000000,
        :traffic_eu       => 150000000,
        :traffic_as       => 50000000,
        :traffic_jp       => 30000000,
        :traffic_unknown  => 10000000,
        :requests_s3      => 100,
        :requests_us      => 200,
        :requests_eu      => 150,
        :requests_as      => 50,
        :requests_jp      => 30,
        :requests_unknown => 10
      )
      Factory(:video_usage, :video => @video1, :log => log,
        :hits             => 100,
        :traffic_s3       => 10000000,
        :traffic_us       => 20000000,
        :traffic_eu       => 15000000,
        :traffic_as       => 5000000,
        :traffic_jp       => 3000000,
        :traffic_unknown  => 1000000,
        :requests_s3      => 10,
        :requests_us      => 20,
        :requests_eu      => 15,
        :requests_as      => 5,
        :requests_jp      => 3,
        :requests_unknown => 1
      )
      Factory(:video_usage, :video => @video2, :log => log,
        :hits             => 1001,
        :traffic_s3       => 100000001,
        :traffic_us       => 200000001,
        :traffic_eu       => 150000001,
        :traffic_as       => 50000001,
        :traffic_jp       => 30000001,
        :traffic_unknown  => 10000001,
        :requests_s3      => 101,
        :requests_us      => 201,
        :requests_eu      => 151,
        :requests_as      => 51,
        :requests_jp      => 31,
        :requests_unknown => 11
      )
      
      @invoice = Factory(:invoice, :user => @user)
    end
    
    let(:total_traffic)  do
      100000000 + 200000000 + 150000000 + 50000000 + 30000000 + 10000000 +
      10000000 + 20000000 + 15000000 + 5000000 + 3000000 + 1000000 +
      100000001 + 200000001 + 150000001 + 50000001 + 30000001 + 10000001 +
      111111
    end
    let(:total_requests) do
      100 + 200 + 150 + 50 + 30 + 10 +
      10 + 20 + 15 + 5 + 3 + 1 +
      101 + 201 + 151 + 51 + 31 + 11
    end
    let(:total_storage)  do
      (((invoice.ended_on.to_time - 10.days.ago) / 1.hour).round * 111111) +
      (((3.days.ago - 10.day.ago) / 1.hour).round * 1111) +
      (((invoice.ended_on.to_time - 3.days.ago) / 1.hour).round * 1112) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 1.hour).round * 222222) +
      (((30.days.ago - invoice.started_on.to_time) / 1.hour).round * 2222) +
      (((5.days.ago - 30.days.ago) / 1.hour).round * 2223) +
      (((invoice.ended_on.to_time - 5.days.ago) / 1.hour).round * 2224) +
      (((invoice.ended_on.to_time - invoice.started_on.to_time) / 1.hour).round * 2225)
    end
    let(:total_encoding_time) { 100 + 101 + 301 + 303 }
    
    let(:invoice) { Invoice.find(@invoice) } # must be deep reloaded!
    subject { Invoice::Videos.new(invoice) }
    
    its(:hits)            { should == 2101 }
    its(:traffic_amount)  { should == (total_traffic.to_f / 1.gigabyte) * Prices.video(:one_GB_of_traffic) }
    its(:storage_amount)  { should == (total_storage.to_f / 1.gigabyte) * Prices.video(:one_GB_per_hour_storage) }
    its(:requests_amount) { should == (total_requests.to_f / 10000) * Prices.video(:ten_thousand_requests) }
    its(:encoding_amount) { should == total_encoding_time.to_f * Prices.video(:one_second_of_encoding) }
    its(:amount)          { should == (((total_traffic.to_f / 1.gigabyte) * Prices.video(:one_GB_of_traffic)) +
                                      ((total_storage.to_f / 1.gigabyte) * Prices.video(:one_GB_per_hour_storage)) +
                                      ((total_requests.to_f / 10000) * Prices.video(:ten_thousand_requests)) +
                                      (total_encoding_time * Prices.video(:one_second_of_encoding))).round }
    
    it "should return video array" do
      videos_ids = subject.collect { |video| video[:id] }
      videos_ids.should include(@video1.id)
      videos_ids.should include(@video2.id)
    end
  end
  
private
  
  def create_videos_with_encoding_for(user)
    @video1 = Factory(:video, :user => user,
      :created_at             => 10.days.ago,
      :file_size              => 111111,
      :hits_cache             => 1000,
      :traffic_s3_cache       => 100000000,
      :traffic_us_cache       => 200000000,
      :traffic_eu_cache       => 150000000,
      :traffic_as_cache       => 50000000,
      :traffic_jp_cache       => 30000000,
      :traffic_unknown_cache  => 10000000,
      :requests_s3_cache      => 100,
      :requests_us_cache      => 200,
      :requests_eu_cache      => 150,
      :requests_as_cache      => 50,
      :requests_jp_cache      => 30,
      :requests_unknown_cache => 10
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
      :created_at             => 40.days.ago,
      :file_size              => 222222,
      :hits_cache             => 1001,
      :traffic_s3_cache       => 100000001,
      :traffic_us_cache       => 200000001,
      :traffic_eu_cache       => 150000001,
      :traffic_as_cache       => 50000001,
      :traffic_jp_cache       => 30000001,
      :traffic_unknown_cache  => 10000001,
      :requests_s3_cache      => 101,
      :requests_us_cache      => 201,
      :requests_eu_cache      => 151,
      :requests_as_cache      => 51,
      :requests_jp_cache      => 31,
      :requests_unknown_cache => 11
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