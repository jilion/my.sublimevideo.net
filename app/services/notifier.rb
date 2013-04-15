class Notifier

  def self.send(message_or_exception, options = {})
    honeybadger(message_or_exception, options)
    if Rails.env.production? || Rails.env.staging?
      ProwlWrapper.notify(message_or_exception)
    end
  end

  private

  def self.honeybadger(message_or_exception, options)
    if message_or_exception.is_a?(Exception)
      Honeybadger.notify_or_ignore(message_or_exception)
    elsif options[:exception]
      Honeybadger.notify_or_ignore(options[:exception], error_message: message_or_exception)
    else # message
      Honeybadger.notify_or_ignore(Exception.new(message_or_exception))
    end
  end

end
