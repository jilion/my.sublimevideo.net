require 'uri'

module UrlsHelper

  def cdn_host
    'cdn.sublimevideo.net'
  end

  def cdn_settings_url(site)
    path = SettingsGenerator.new(site).cdn_path
    cdn_url(path)
  end

  def docs_page_url(path)
    page_url(path, subdomain: 'docs', protocol: 'http')
  end

  def www_page_url(path)
    page_url(path, subdomain: false, protocol: 'http')
  end

  def cdn_url(path)
    protocol, host = case Rails.env
                     when 'development'
                       ['http://', "s3.amazonaws.com/#{S3Wrapper.buckets[:sublimevideo]}"]
                     when 'staging'
                       ['http://', 'cdn.sublimevideo-staging.net']
                     else
                       ['//', 'cdn.sublimevideo.net']
                     end

    protocol + [host, path].join('/').squeeze('/')
  end

  def cdn_path_from_full_url(full_url)
    return '' if full_url.blank?

    host = case Rails.env
           when 'development'
             "s3.amazonaws.com/#{S3Wrapper.buckets[:sublimevideo]}"
           when 'staging'
             'cdn.sublimevideo-staging.net'
           else
             'cdn.sublimevideo.net'
           end

    full_url.sub(%r{(https?:)?//#{host}/}, '')
  end

end
