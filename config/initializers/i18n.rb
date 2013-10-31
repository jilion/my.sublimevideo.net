module I18n
  class JustRaiseExceptionHandler < ExceptionHandler
    def call(exception, locale, key, options)
      case Rails.env
      when 'development'
        raise exception.to_exception
      when 'staging', 'production'
        Notifier.send(exception.to_exception)
      else
        super
      end
    end
  end
end

I18n.exception_handler = I18n::JustRaiseExceptionHandler.new
