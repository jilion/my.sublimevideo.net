require_dependency 'logs_file_format/amazon'
Dir["#{Rails.root}/lib/logs_file_format/s3_*"].each do |file|
  require_dependency file
end

require_dependency 'logs_file_format/voxcast'
Dir["#{Rails.root}/lib/logs_file_format/voxcast_*"].each do |file|
  require_dependency file
end
