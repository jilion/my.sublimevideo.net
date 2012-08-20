require_dependency 'prowl_wrapper'

module Notify

  class << self

    def send(message, options = {})
      airbrake(message, options)
      ProwlWrapper.notify(message) if Rails.env.production? || Rails.env.staging?
    end

  private

    def airbrake(message, options)
      if options[:exception]
        Airbrake.notify(Exception.new(message + " // exception: #{options[:exception]}"))
      else
        Airbrake.notify(Exception.new(message))
      end
    end

  end

end
