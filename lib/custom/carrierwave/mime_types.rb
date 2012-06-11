require_dependency 'file_header'

module Custom
  module CarrierWave

    module MimeTypes
      def set_content_type(override=false)
        new_content_type = FileHeader.content_type(filename)
        if file.respond_to?(:content_type=)
          file.content_type = new_content_type
        else
          file.set_instance_variable(:@content_type, new_content_type)
        end
      end
    end

  end
end
