require_dependency 'active_model'
require_dependency 's3'

module Addons
  CustomLogo = Struct.new(:kit, :file) do
    include ActiveModel::Validations

    delegate :site, to: :kit

    validates :file, presence: true
    validate :content_type

    def content_type
      unless file.content_type == 'image/png'
        errors.add(:base, 'Image content type must be "image/png".')
      end
    end

    def path
      "a/#{site.token}/#{kit.identifier}/logo-custom@2x.png"
    end

    def url
      S3.bucket_url(S3.buckets['sublimevideo']) + path
    end

  end
end
