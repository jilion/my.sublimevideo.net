AssetSync.configure do |config|
  config.fog_provider          = 'AWS'
  config.aws_access_key_id     = 'AKIAJVHSNREHOLGAAR4A'
  config.aws_secret_access_key = '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'
  config.fog_directory         = 'assets.sublimevideo-staging.net'

  config.existing_remote_files = "delete"
  # config.gzip_compression = true # don't working, doesn't uploads gz files version

  # Increase upload performance by configuring your region
  # config.fog_region = 'eu-west-1'
  #
  # Don't delete files from the store
  #
  # Automatically replace files with their equivalent gzip compressed version
  #
  # Use the Rails generated 'manifest.yml' file to produce the list of files to
  # upload instead of searching the assets directory.
  # config.manifest = true
end