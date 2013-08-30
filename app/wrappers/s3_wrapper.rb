require 'active_support/core_ext'

module S3Wrapper

  BUCKETS = {
    'development' => {
      sublimevideo:                'dev.sublimevideo',
      player:                      'dev.sublimevideo.player',
      logs:                        'dev.sublimevideo.logs',
      stats_exports:               'dev.sublimevideo.stats.exports',
      videos_upload:               'dev.sublimevideo.videos.uploads',
      tailor_made_player_requests: 'dev-sublimevideo-tailor-made-player-requests'
    },
    'staging' => {
      sublimevideo:                'staging.sublimevideo',
      player:                      'staging.sublimevideo.player',
      logs:                        'staging.sublimevideo.logs',
      stats_exports:               'staging.sublimevideo.stats.exports',
      videos_upload:               'staging.sublimevideo.videos.uploads',
      tailor_made_player_requests: 'staging-sublimevideo-tailor-made-player-requests'
    },
    'production' => {
      sublimevideo:                'sublimevideo',
      player:                      'sublimevideo.player',
      logs:                        'sublimevideo.logs',
      stats_exports:               'sublimevideo.stats.exports',
      videos_upload:               'sublimevideo.videos.uploads',
      tailor_made_player_requests: 'sublimevideo-tailor-made-player-requests'
    }
  }

  def self.buckets
    @@_buckets ||= case Rails.env
                   when 'development', 'test'
                     BUCKETS['development']
                   else
                     BUCKETS[Rails.env]
                   end
  end

  def self.bucket_url(bucket)
    "https://s3.amazonaws.com/#{bucket}/"
  end

  def self.fog_connection
    @fog_connection ||= Fog::Storage.new(
      provider:              'AWS',
      aws_access_key_id:     ENV['S3_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
      region:                'us-east-1'
    )
  end
end



