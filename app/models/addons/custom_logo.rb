require 'active_model'
require_dependency 's3'

module Addons
  CustomLogo = Struct.new(:file) do
    include ActiveModel::Validations

    validates :file, presence: true
    validate :content_type

    def content_type
      unless file.content_type == 'image/png'
        errors.add(:base, 'Image content type must be "image/png".')
      end
    end
  end
end
