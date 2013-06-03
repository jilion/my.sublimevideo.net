module UploadsHelper

  # def s3_uploader options = {}
  #   options[:uploader_path] ||= 'uploader/uploader.html'
  #   options[:uploaded_files_path] ||= "#{controller_name}/:uuid"
  #   options[:create_resource_url] ||= url_for(only_path: false)
  #   options[:resource_name] ||= controller_name.singularize

  #   upload_params = { key: s3_key(options[:uploaded_files_path]),
  #                     AWSAccessKeyId: S3Wrapper.send(:access_key_id),
  #                     bucket: s3_bucket_url,
  #                     _policy: s3_policy(path: options[:uploaded_files_path]),
  #                     _signature: s3_signature(path: options[:uploaded_files_path]) }.to_query

  #   content_tag :iframe, '',
  #               src: "https://s3.amazonaws.com/#{S3Wrapper.buckets['videos_upload']}/#{options[:uploader_path]}?#{upload_params}",
  #               frameborder: 0,
  #               height: options[:iframe_height] || 60,
  #               width: options[:iframe_width] || 500,
  #               data: { create_resource_url: options[:create_resource_url] }
  # end

  def s3_key(path)
    "#{path}/${filename}"
  end

  def s3_policy(options = {})
    options[:content_type]  ||= ''
    options[:acl]           ||= 'private'
    options[:max_file_size] ||= 500.megabyte
    options[:path]          ||= ''

    Base64.encode64(
      "{'expiration': '#{10.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')}',
        'conditions': [
          {'bucket': '#{options[:bucket]}'},
          ['starts-with', '$key', ''],
          ['starts-with', '$name', ''],
          ['starts-with', '$Filename', ''],
          ['starts-with', '$success_action_status', ''],
          {'acl': '#{options[:acl]}'},
          {'success_action_status': '201'},
          ['content-length-range', 0, #{options[:max_file_size]}]
        ]
    }").gsub(/\n|\r/, '')
  end

  def s3_signature(options = {})
    Base64.encode64(
      OpenSSL::HMAC.digest(
      OpenSSL::Digest::Digest.new('sha1'),
      ENV['S3_SECRET_ACCESS_KEY'], s3_policy(options))
    ).gsub("\n", '')
  end

  def upload_params(options = {})
    params = {}
    params[:key]                   = options[:s3_key]
    params[:Filename]              = options[:s3_key]
    params[:AWSAccessKeyId]        = ENV['S3_ACCESS_KEY_ID']
    params[:acl]                   = options[:acl] || 'private'
    params[:success_action_status] = '201'
    params[:policy]                = s3_policy(options)
    params[:signature]             = s3_signature(options)

    params
  end

end
