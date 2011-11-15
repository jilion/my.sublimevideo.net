module Docs::CoderayHelper

  def coderay_options(language, options = {})
    options.reverse_merge!(css: :class)

    Haml::Filters::CodeRay.encoder_options = options
    "#!#{language.to_s}"
  end

end
