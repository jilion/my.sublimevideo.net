# Setup logs file to imitate S3 paths
RSpec.configure do |config|
  config.before(:suite) do
    %w[s3/sublimevideo.player s3/sublimevideo.loaders s3/sublimevideo.licenses].each do |path|
      FileUtils.mkdir_p("public/uploads/#{path}")
    end

    # S3 Player
    s3_player_log_file = "#{Rails.public_path}/uploads/s3/sublimevideo.player/2010-07-16-05-22-13-8C4ECFE09170CCD5"
    FileUtils.rm(s3_player_log_file, :force => true)
    FileUtils.cp(
      Rails.root.join('spec/fixtures/logs/s3_player/2010-07-16-05-22-13-8C4ECFE09170CCD5'),
      s3_player_log_file
    )
    # S3 Loaders
    s3_loader_log_file = "#{Rails.public_path}/uploads/s3/sublimevideo.loaders/2010-07-14-09-22-26-63B226D3944909C8"
    FileUtils.rm(s3_loader_log_file, :force => true)
    FileUtils.cp(
      Rails.root.join('spec/fixtures/logs/s3_loaders/2010-07-14-09-22-26-63B226D3944909C8'),
      s3_loader_log_file
    )
    # S3 Licenses
    s3_license_log_file = "#{Rails.public_path}/uploads/s3/sublimevideo.licenses/2010-07-14-11-29-03-BDECA2599C0ADB7D"
    FileUtils.rm(s3_license_log_file, :force => true)
    FileUtils.cp(
      Rails.root.join('spec/fixtures/logs/s3_licenses/2010-07-14-11-29-03-BDECA2599C0ADB7D'),
      s3_license_log_file
    )
  end
end
