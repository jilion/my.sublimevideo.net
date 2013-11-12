module TimeParsable
  extend ActiveSupport::Concern

  def time
    Time.parse(t)
  end
end
