require 'spec_helper'

describe Referrer do

  describe "Validations" do
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:token) }

    it { should allow_value("http://rymai.com").for(:url) }
    it { should allow_value("https://rymai.com").for(:url) }
    it { should_not allow_value("-").for(:url) }
  end

  describe ".create_or_update_from_trackers!" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960')
      @trackers = LogAnalyzer.parse(log_file, 'VoxcastReferrersLogFileFormat')
    end
    before do
      %w[0w1o1q3c k8qaaj1l ibvjcopp hp1lepyq].each do |token|
        create(:site).update_attribute(:token, token)
      end
      Referrer.create_or_update_from_trackers!(@trackers)
    end

    let(:site) { Site.where(token: 'ibvjcopp').first }

    it { Referrer.count.should eq 2 }

    describe "second referrer" do
      let(:referrer) { Referrer.all.first }

      it "should have valid attributes" do
        referrer.url.should include "sublimevideo.net/demo"
        referrer.token.should eq site.token
        referrer.hits.should eq 1
        referrer.created_at.should be_present
        referrer.updated_at.should be_present
      end

      it "should update hits if same referrer reparsed" do
        Referrer.create_or_update_from_trackers!(@trackers)

        referrer.reload.hits.should eq 2
        Referrer.count.should eq 2
      end

      it "should update updated_at on hits incrementation" do
        old_update_at = referrer.updated_at
        Timecop.travel(Time.now + 1.minute) do
          Referrer.create_or_update_from_trackers!(@trackers)
          referrer.reload.updated_at.should_not <= old_update_at
        end
      end
    end
  end

end
