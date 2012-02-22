module FileHeader

  def self.content_type(filename)
    case File.extname(filename)
    when '.js', '.jgz'
      'text/javascript'
    else
      MIME::Types.type_for(filename).first.to_s
    end
  end

  def self.content_encoding(filename)
    case File.extname(filename)
    when '.jgz', '.gz'
      'gzip'
    else
      nil
    end
  end

end
