class TailorMadePlayerRequest
  include SublimeVideoPrivateApi::Model
  uses_private_api :www

  def self.topics
    @topics ||= get_raw(:topics)[:parsed_data][:data]
  end

  def document?
    document[:url].present?
  end

  def document_url
    document[:url]
  end
end
