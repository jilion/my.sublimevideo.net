# Setup logs file to imitate S3 paths

RSpec.configure do |config|
  config.before(:all) do
    %w[cloudfront/sublimevideo.videos/download cloudfront/sublimevideo.videos/streaming s3/sublimevideo.videos].each do |path|
      FileUtils.mkdir_p("public/uploads/#{path}")
    end
    
    # Cloudfront Download
    cloudfront_download_log_file = "#{Rails.public_path}/uploads/cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz"
    FileUtils.rm cloudfront_download_log_file, :force => true
    FileUtils.cp(
      Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'),
      cloudfront_download_log_file
    )
    # Cloudfront Streaming
    cloudfront_streaming_log_file = "#{Rails.public_path}/uploads/cloudfront/sublimevideo.videos/streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz"
    FileUtils.rm cloudfront_streaming_log_file, :force => true
    FileUtils.cp(
      Rails.root.join('spec/fixtures/logs/cloudfront_streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz'),
      cloudfront_streaming_log_file
    )
    # S3 Videos
    s3_videos_log_file = "#{Rails.public_path}/uploads/s3/sublimevideo.videos/2010-06-23-08-20-45-DE5461BCB46DA093"
    FileUtils.rm s3_videos_log_file, :force => true
    FileUtils.cp(
      Rails.root.join('spec/fixtures/logs/s3_videos/2010-06-23-08-20-45-DE5461BCB46DA093'),
      s3_videos_log_file
    )
  end
end