# Setup logs file to imitate S3 paths

RSpec.configure do |config|
  config.before(:all) do
    %w[cloudfront/sublimevideo.videos/download cloudfront/sublimevideo.videos/streaming s3/sublimevideo.videos].each do |path|
      FileUtils.mkdir_p("public/uploads/#{path}")
    end
    
    # Cloudfront Download
    cloudfront_download_log_file = "cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz"
    unless File.exist?("public/uploads/#{cloudfront_download_log_file}")
      FileUtils.cp(
        Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'),
        File.join("#{Rails.public_path}/uploads/#{cloudfront_download_log_file}")
      )
    end
    # Cloudfront Streaming
    cloudfront_streaming_log_file = "cloudfront/sublimevideo.videos/streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz"
    unless File.exist?("public/uploads/#{cloudfront_streaming_log_file}")
      FileUtils.cp(
        Rails.root.join('spec/fixtures/logs/cloudfront_streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz'),
        File.join("#{Rails.public_path}/uploads/#{cloudfront_streaming_log_file}")
      )
    end
    
    # S3 Videos
    s3_videos_log_file = "s3/sublimevideo.videos/2010-06-23-08-20-45-DE5461BCB46DA093"
    unless File.exist?(File.join("#{Rails.public_path}/uploads/#{s3_videos_log_file}"))
      FileUtils.cp(
        Rails.root.join('spec/fixtures/logs/s3_videos/2010-06-23-08-20-45-DE5461BCB46DA093'),
        File.join("#{Rails.public_path}/uploads/#{s3_videos_log_file}")
      )
    end
  end
end