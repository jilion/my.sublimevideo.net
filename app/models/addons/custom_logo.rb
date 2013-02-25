require 'active_model'

module Addons
  class CustomLogo
    include ActiveModel::Validations

    attr_reader :file

    validates :file, presence: true
    validate :content_type

    def initialize(file)
      @file = file
    end

    def content_type
      unless file.content_type == 'image/png'
        errors.add(:base, 'Image content type must be "image/png".')
      end
    end
  end
end
