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
      total_count: results.metadata[:total_count])
  end

  def created_at
    @created_at ||= Time.parse(@data[:created_at])
  end

  # Needed for url [:admin, ...] generation
  def persisted?
    true
  end

end
