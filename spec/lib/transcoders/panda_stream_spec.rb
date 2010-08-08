require 'spec_helper'

ID = 'f72e511820c12dabc1d15817745225bd'

describe Transcoders::PandaStream do
  
  describe ".get(item)" do
    before(:each) { VCR.insert_cassette('panda/get') }
    
    it "should return the equivalent of Panda.get('/videos.json') response" do
      response = Transcoders::PandaStream.get(:video)
      response.should == Panda.get("/videos.json").map(&:symbolize_keys!)
    end
    
    it "should return the equivalent of Panda.get('/encodings.json') response" do
      response = Transcoders::PandaStream.get(:encoding)
      response.should == Panda.get("/encodings.json").map(&:symbolize_keys!)
    end
    
    it "should return the equivalent of Panda.get('/profiles.json') response" do
      response = Transcoders::PandaStream.get(:profile)
      response.should == Panda.get("/profiles.json").map(&:symbolize_keys!)
    end
    
    it "should raise an exception if the item given is not allowed" do
      lambda { Transcoders::PandaStream.get(:foo) }.should raise_error(RuntimeError, ":foo is not valid!")
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe ".get(item, id)" do
    before(:each) { VCR.insert_cassette('panda/get') }
    
    it "should return the equivalent of Panda.get('/videos/ID.json') response" do
      response = Transcoders::PandaStream.get(:video, ID)
      response.should == Panda.get("/videos/#{ID}.json").symbolize_keys!
    end
    
    it "should return the equivalent of Panda.get('/encodings/ID.json') response" do
      response = Transcoders::PandaStream.get(:encoding, ID)
      response.should == Panda.get("/encodings/#{ID}.json").symbolize_keys!
    end
    
    it "should return the equivalent of Panda.get('/profiles/ID.json') response" do
      response = Transcoders::PandaStream.get(:profile, ID)
      response.should == Panda.get("/profiles/#{ID}.json").symbolize_keys!
    end
    
    it "should return the equivalent of Panda.get('/clouds/ID.json') response" do
      response = Transcoders::PandaStream.get(:cloud, ID)
      response.should == Panda.get("/clouds/#{ID}.json").symbolize_keys!
    end
    
    it "should raise an exception if the item given is not allowed" do
      lambda { Transcoders::PandaStream.get(:foo, ID) }.should raise_error(RuntimeError, ":foo is not valid!")
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe ".get([item, children], id)" do
    before(:each) { VCR.insert_cassette('panda/get') }
    
    it "should return the equivalent of Panda.get('/videos/ID/encodings.json') response" do
      response = Transcoders::PandaStream.get([:video, :encoding], ID)
      response.should == Panda.get("/videos/#{ID}/encodings.json").map(&:symbolize_keys!)
    end
    
    it "should raise an exception if the item given is not allowed" do
      lambda { Transcoders::PandaStream.get([:video, :foo], ID) }.should raise_error(RuntimeError, "[:video, :foo] is not valid!")
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe ".post(item, hash)" do
    before(:each) { VCR.insert_cassette('panda/post') }
    
    it "should return the equivalent of Panda.post('/videos.json', params) response" do
      params = { :file => "#{Rails.root}/spec/fixtures/railscast_intro.mov" }
      response = Transcoders::PandaStream.post(:video, params)
      response.should == Panda.post("/videos.json", params).symbolize_keys!
    end
    
    it "should return the equivalent of Panda.post('/encodings.json', params) response" do
      params = { :video_id => '1', :profile_id => '1' }
      response = Transcoders::PandaStream.post(:encoding, params)
      response.should == Panda.post("/encodings.json", params).symbolize_keys!
    end
    
    it "should return the equivalent of Panda.post('/profiles.json', params) response" do
      params = { :title => "My custom profile", :extname => ".mp4", :width => 320, :height => 240, 
      :command => "ffmpeg -i $input_file$ -f mp4 -b 128k $resolution_and_padding$ -y $output_file$" }
      response = Transcoders::PandaStream.post(:profile, params)
      response.should == Panda.post("/profiles.json", params).symbolize_keys!
    end
    
    it "should raise an exception if the item given is not allowed" do
      lambda { Transcoders::PandaStream.post(:foo) }.should raise_error(RuntimeError, ":foo is not valid!")
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe ".post(item, id, :action => 'retry')" do
    before(:each) { VCR.insert_cassette('panda/retry') }
    
    it "should return the equivalent of Panda.retry('/encodings/ID/retry.json') response" do
      response = Transcoders::PandaStream.retry(:encoding, ID)
      response.should == Panda.post("/encodings/#{ID}/retry.json").symbolize_keys!
    end
    
    it "should raise an exception if the item given is not allowed" do
      lambda { Transcoders::PandaStream.retry(:foo, ID) }.should raise_error(RuntimeError, ":foo is not valid!")
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe ".put(item, id, hash)" do
    before(:each) { VCR.insert_cassette('panda/put') }
    
    it "should return the equivalent of Panda.put('/profiles/ID.json', params) response" do
      params = { :title => "My own custom profile", :extname => ".mp4", :width => 320, :height => 240, 
      :command => "ffmpeg -i $input_file$ -f mp4 -b 128k $resolution_and_padding$ -y $output_file$" }
      response = Transcoders::PandaStream.put(:profile, ID, params)
      response.should == Panda.put("/profiles/#{ID}.json", params).symbolize_keys!
    end
    
    it "should raise an exception if the item given is not allowed" do
      lambda { Transcoders::PandaStream.put(:foo, ID) }.should raise_error(RuntimeError, ":foo is not valid!")
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  # pending until the API error is fixed
  describe ".delete(item, id)" do
    before(:each) { VCR.insert_cassette('panda/delete') }
    
    it "should return the equivalent of Panda.delete('/videos/ID.json') response" do
      response = Transcoders::PandaStream.delete(:video, ID)
      response.should == Panda.delete("/videos/#{ID}.json").symbolize_keys!
    end
    
    it "should return the equivalent of Panda.delete('/encodings/ID.json') response" do
      response = Transcoders::PandaStream.delete(:encoding, ID)
      response.should == Panda.delete("/encodings/#{ID}.json").symbolize_keys!
    end
    
    it "should return the equivalent of Panda.delete('/profiles/ID.json') response" do
      response = Transcoders::PandaStream.delete(:profile, ID)
      response.should == Panda.delete("/profiles/#{ID}.json").symbolize_keys!
    end
    
    it "should raise an exception if the item given is not allowed" do
      lambda { Transcoders::PandaStream.delete(:foo, ID) }.should raise_error(RuntimeError, ":foo is not valid!")
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
end