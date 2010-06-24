# Setup logs file to imitate S3 paths

RSpec.configure do |config|
  config.before(:all) do
    Dir.mkdir('public/uploads/') unless File.exist?('public/uploads/')
    # Cloudfront
    Dir.mkdir('public/uploads/cloudfront/') unless File.exist?('public/uploads/cloudfront/')
    Dir.mkdir('public/uploads/cloudfront/sublimevideo.videos/') unless File.exist?('public/uploads/cloudfront/sublimevideo.videos/')
    # Cloudfront Download
    Dir.mkdir('public/uploads/cloudfront/sublimevideo.videos/download/') unless File.exist?('public/uploads/cloudfront/sublimevideo.videos/download/')
    unless File.exist?('public/uploads/cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz')
      FileUtils.cp(
        Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'),
        Rails.root.join('public/uploads/cloudfront/sublimevideo.videos/download/')
      )
    end
    # Cloudfront Streaming
    Dir.mkdir('public/uploads/cloudfront/sublimevideo.videos/streaming/') unless File.exist?('public/uploads/cloudfront/sublimevideo.videos/streaming/')
    unless File.exist?('public/uploads/cloudfront/sublimevideo.videos/streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz')
      FileUtils.cp(
        Rails.root.join('spec/fixtures/logs/cloudfront_streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz'),
        Rails.root.join('public/uploads/cloudfront/sublimevideo.videos/streaming/')
      )
    end
    # S3
    Dir.mkdir('public/uploads/s3/') unless File.exist?('public/uploads/s3/')
    # S3 Videos
    Dir.mkdir('public/uploads/s3/sublimevideo.videos/') unless File.exist?('public/uploads/s3/sublimevideo.videos/')
    unless File.exist?('public/uploads/s3/sublimevideo.video/2010-06-23-08-20-45-DE5461BCB46DA093')
      FileUtils.cp(
        Rails.root.join('spec/fixtures/logs/s3_videos/2010-06-23-08-20-45-DE5461BCB46DA093'),
        Rails.root.join('public/uploads/s3/sublimevideo.videos/')
      )
    end
  end
end