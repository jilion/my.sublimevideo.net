require 'spec_helper'

describe S3 do
  
  describe "yml key access" do
    subject { S3 }
    
    its(:cnamed)            { should be_false }
    its(:access_key_id)     { should be_present }
    its(:secret_access_key) { should be_present }
  end
  
  describe "logs list" do
    
    it "should return max 100 keys" do
      VCR.use_cassette('s3/logs_bucket_all_keys') do
        S3.logs_name_list.should have(100).names
      end
    end
    
    it "should filter with prefix" do
      VCR.use_cassette('s3/logs_bucket_with_prefix') do
        names = S3.logs_name_list(
          'prefix' => 'cloudfront/sublimevideo.videos/download/'
        )
        names.should have(5).names
        names.should == [
          "cloudfront/sublimevideo.videos/download/",
          "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-15-14.JWGUoNHt.gz",
          "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-15-14.O5iQjgcX.gz",
          "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-15-14.fqabil9m.gz",
          "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-07.nWuabAEC.gz"
        ]
      end
    end
    
    it "should filter with prefix & remove_prefix options" do
      VCR.use_cassette('s3/logs_bucket_with_prefix') do
        names = S3.logs_name_list(
          'prefix' => 'cloudfront/sublimevideo.videos/download/',
          :remove_prefix => true
        )
        names.should have(4).names
        names.should == [
          "E3KTK13341WJO.2010-06-15-14.JWGUoNHt.gz",
          "E3KTK13341WJO.2010-06-15-14.O5iQjgcX.gz",
          "E3KTK13341WJO.2010-06-15-14.fqabil9m.gz",
          "E3KTK13341WJO.2010-06-16-07.nWuabAEC.gz"
        ]
      end
    end
    
    it "should filter with prefix and marker" do
      VCR.use_cassette('s3/logs_bucket_with_prefix_and_marker') do
        names = S3.logs_name_list(
          'prefix' => 'cloudfront/sublimevideo.videos/download/',
          'marker' => "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-15-14.JWGUoNHt.gz"
        )
        names.should have(3).names
        names.should == [
          "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-15-14.O5iQjgcX.gz",
          "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-15-14.fqabil9m.gz",
          "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-07.nWuabAEC.gz"
        ]
      end
    end
    
  end
  
end
