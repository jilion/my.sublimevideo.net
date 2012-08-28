require 'tempfile'
require_dependency 'cdn'

class Player::Loader < Struct.new(:tag, :version, :file)

  TEMPLATE_PATH = Rails.root.join("app/templates/player/loader.js.erb")

  def self.update!(tag, version)
    loader = new(tag, version)
    loader.upload!
  end

  def initialize(*args)
    super
    generate_file
  end

  def upload!
    File.open(file) do |f|
      S3.fog_connection.put_object(
        S3.buckets['sublimevideo'],
        filename,
        f.read,
        {
          'Cache-Control' => 'max-age=300, public', # 5 minutes
          'Content-Type'  => 'text/javascript',
          'x-amz-acl'     => 'public-read'
        }
      )
    end
    CDN.purge(filename)
  end

  def filename
    if tag == 'stable'
      'loader.js'
    else
      "loader-#{tag}.js"
    end
  end

private

  def generate_file
    template = ERB.new(File.new(TEMPLATE_PATH).read)
    self.file = Tempfile.new([filename, '.js'], "#{Rails.root}/tmp")
    self.file.print template.result(binding)
    self.file.flush
  end

end
