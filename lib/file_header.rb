module FileHeader

  def self.content_type(filename)
    case File.extname(filename)
    when '.js', '.jgz'
      'text/javascript'
    else
      MIME::Types.type_for(filename).first.try(:content_type)
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
