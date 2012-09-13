require_dependency 'prowl_wrapper'

module Notify

  class << self

    def send(message_or_exception, options = {})
      airbrake(message_or_exception, options)
      if Rails.env.production? || Rails.env.staging?
        ProwlWrapper.notify(message_or_exception)
      end
    end

  private

    def airbrake(message_or_exception, options)
      if message_or_exception.is_a?(Exception)
        Airbrake.notify(message_or_exception)
      elsif options[:exception]
        Airbrake.notify(options[:exception], error_message: message_or_exception)
      else # message
        Airbrake.notify(Exception.new(message_or_exception))
      end
    end

  end

end
