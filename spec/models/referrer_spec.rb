require 'spec_helper'

describe Referrer do

  describe "Validations" do
    [:token, :url, :hits].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:token) }

    it { should allow_value("http://rymai.com").for(:url) }
    it { should allow_value("https://rymai.com").for(:url) }
    it { should_not allow_value("-").for(:url) }
  end

  describe ".create_or_update_from_trackers!" do
    before(:all) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastReferrers')
      %w[0w1o1q3c k8qaaj1l ibvjcopp hp1lepyq].each do |token|
        FactoryGirl.create(:site).update_attribute(:token, token)
      end
    end
    before(:each) { Referrer.create_or_update_from_trackers!(@trackers) }

    let(:site) { Site.find_by_token('k8qaaj1l') }

    it { Referrer.count.should == 5 }

    describe "second referrer" do
      subject { Referrer.all.first }

      it "should have valid attributes" do
        subject.url.should == 'http://www.killy.net/'
        subject.token.should == site.token
        subject.site_id.should == site.id
        subject.hits.should == 3
        subject.created_at.should be_present
        subject.updated_at.should be_present
      end

      it "should update hits if same referrer reparsed" do
        Referrer.create_or_update_from_trackers!(@trackers)

        subject.reload.hits.should == 6
        Referrer.count.should == 5
      end

      it "should update updated_at on hits incrementation" do
        old_update_at = subject.updated_at
        Timecop.travel(Time.now + 1.minute)

        Referrer.create_or_update_from_trackers!(@trackers)

        subject.reload.updated_at.should_not <= old_update_at
      end
    end
  end

  describe ".create_or_update_from_type!" do
    let(:site) { FactoryGirl.create(:site) }

    it "should create referrer and set contextual_hits to 1 if url/token doesn't exist" do
      expect { Referrer.create_or_update_from_type!(site.token, 'http://www.bob.com', 'c') }.should change(Referrer, :count).by(1)
      Referrer.last.contextual_hits.should == 1
    end

    it "should increment contextual_hits if referrer url/token already exsits" do
      Referrer.create_or_update_from_type!(site.token, 'http://www.bob.com', 'c')
      Referrer.last.contextual_hits.should == 1
      expect { Referrer.create_or_update_from_type!(site.token, 'http://www.bob.com', 'c') }.should change(Referrer, :count).by(0)
      Referrer.last.contextual_hits.should == 2
    end
  end
end
