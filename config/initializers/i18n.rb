module I18n
  class JustRaiseExceptionHandler < ExceptionHandler
    def call(exception, locale, key, options)
      if exception.is_a?(MissingTranslation)
        if %w[staging production].include?(Rails.env)
          Notifier.send(exception.to_exception)
        else
          raise exception.to_exception
        end
      else
        super
      end
    end
  end
end

I18n.exception_handler = I18n::JustRaiseExceptionHandler.new
