require 'kaminari'
require 'kaminari/models/array_extension'

class TailorMadePlayerRequest
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include Her::Model

  uses_api $www_api

  def self.all(params = {})
    results = super(params)
    Kaminari.paginate_array(
      results,
      limit: results.metadata[:limit],
      offset: results.metadata[:offset],
      total_count: results.metadata[:total_count]).page(params[:page])
  end

  def self.count(params = {})
    all(params).total_count
  end

  def self.topics
    @topics ||= get_raw(:topics)[:data]
  end

  def created_at
    @created_at ||= Time.parse(@data[:created_at])
  end

  # Needed for url [:admin, ...] generation
  def persisted?
    !new?
  end

  def document?
    document[:url].present?
  end

  def document_url
    document[:url]
  end

end
