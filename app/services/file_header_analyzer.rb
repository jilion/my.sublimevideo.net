require 'mime/types'

class FileHeaderAnalyzer
  attr_reader :filename

  def initialize(filename)
    @filename = filename
  end

  def content_type
    @content_type ||= case File.extname(filename)
                      when '.js', '.jgz'
                        'text/javascript'
                      else
                        MIME::Types.type_for(filename).first.to_s
                      end
  end

end
