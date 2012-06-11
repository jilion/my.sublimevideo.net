Dir["#{Rails.root}/lib/logs_file_format/*"].each do |file|
  require_dependency file
end
