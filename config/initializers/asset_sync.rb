AssetSync.configure do |config|
  config.fog_provider = 'AWS'
  config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID'] || 'AKIAJ2FJVCFJW3RZRUUQ'
  config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || 'xJtl+EZj67FLsele0jlI0hYuth743MFciqQWq1se'
  config.fog_directory = ENV['FOG_DIRECTORY'] || 'sv_assets'

  # Increase upload performance by configuring your region
  # config.fog_region = 'eu-west-1'
  #
  # Don't delete files from the store
  # config.existing_remote_files = "keep"
  #
  # Automatically replace files with their equivalent gzip compressed version
  config.gzip_compression = true
  #
  # Use the Rails generated 'manifest.yml' file to produce the list of files to
  # upload instead of searching the assets directory.
  config.manifest = true
end