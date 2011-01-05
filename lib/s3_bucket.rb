class S3Bucket < Settingslogic
  source "#{Rails.root}/config/s3_bucket.yml"
  namespace Rails.env
end