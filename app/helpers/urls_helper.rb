module UrlsHelper

  def docs_page_url(path)
    page_url(path, subdomain: 'docs', protocol: 'http')
  end

  def www_page_url(path)
    page_url(path, subdomain: false, protocol: 'http')
  end

  def cdn_url(path)
    protocol, host = case Rails.env
    when 'development'
      ['http://', "s3.amazonaws.com/#{S3.buckets['sublimevideo']}"]
    when 'staging'
      ['http://', 'cdn.sublimevideo.net-staging']
    else
      ['//', 'cdn.sublimevideo.net']
    end

    protocol + [host, path].join('/').squeeze('/')
  end

end
