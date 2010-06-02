# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  user_id     :integer
#  original_id :integer
#  panda_id    :string(255)
#  name        :string(255)
#  token       :string(255)
#  file        :string(255)
#  thumbnail   :string(255)
#  codec       :string(255)
#  container   :string(255)
#  size        :integer
#  duration    :integer
#  width       :integer
#  height      :integer
#  state       :string(255)
#  type        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe VideoOriginal do
  
  before(:all) do
    VCR.use_cassette('videos/video_upload') do
      # fake video upload, just to get the panda_id
      @panda_id = JSON[Panda.post("/videos.json", :file => File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov"))]['id']
    end
  end
  
  pending "built with valid attributes" do
    subject { Factory.build(:video_original, :panda_id => @panda_id) }
    
    it { subject.panda_id.should    be_present         }
    it { subject.user.should        be_present         }
    it { subject.original_id.should be_nil             }
    it { subject.name.should        be_nil             }
    it { subject.token.should       be_nil             }
    it { subject.file.should        be_present         }
    it { subject.type               == 'VideoOriginal' }
    it { subject.should             be_active          }
  end
  
  pending "created with valid attributes" do
    before(:each) { VCR.insert_cassette('videos/one_saved_video') }
    
    subject { Factory(:video_original, :panda_id => @panda_id) }
    
    it { subject.name.should  == "Railscast Intro" }
    it { subject.token.should =~ /^[a-z0-9]{8}$/   }
    
    it "should encode after create" do
      subject # trigger video creation
      subject.formats.size.should == VideoOriginal.profiles.size
      # JSON[Panda.get("/encodings/#{subject.panda_id}.json")].size.should == VideoOriginal.profiles.size
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Validations" do
    it "should validate presence of [:user] on build" do
      video = Factory.build(:video_original, :user => nil)
      video.should_not be_valid
      video.errors[:user].should be_present
    end
  end
  
  pending "State Machine" do
    before(:each) { VCR.insert_cassette('videos/state_machine') }
    
    it "deactivate should deactivate each formats as well" do
      original = Factory(:video_original, :panda_id => @panda_id)
      original.should be_pending
      
      original.formats.each { |f| f.activate; f.reload; f.should be_active }
      
      original.should be_active
      
      original.deactivate
      original.should be_pending
      
      original.formats.each { |f| f.should be_pending }
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Callbacks" do
  end
  
  describe "Class Methods" do
    describe ".profiles" do
      it "should return the current profiles we have in Panda" do
        VCR.use_cassette('videos/profiles') do
          # VideoOriginal.profiles.should == 2
        end
      end
    end
  end
  
  describe "Instance Methods" do
    pending "#total_size" do
      before(:each) { VCR.insert_cassette('videos/total_size') }
      
      it "should return total storage (original size + formats sizes)" do
        original = Factory(:video_original, :panda_id => @panda_id)
        VideoOriginal.stub(:size).and_return(3)
        VideoFormat.stub(:size).and_return(2)
        
        original.total_size.should == 3 + original.formats.count * 2
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    pending "#all_formats_active" do
      it "should return true if all the formats of a original video are active" do
        original = Factory(:video_original)
        format1  = Factory(:video_format, :original => original)
        format2  = Factory(:video_format, :original => original)
        original.formats.should == [format1, format2]
        original.all_formats_active?.should be_false
        
        format1.activate
        format1.should be_active
        original.all_formats_active?.should be_false
        
        format2.activate
        format2.should be_active
        original.reload
        
        original.all_formats_active?.should be_true
      end
    end
  end
  
end
