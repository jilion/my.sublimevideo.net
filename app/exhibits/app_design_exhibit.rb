# coding: utf-8
class AppDesignExhibit < DisplayCase::Exhibit

  def self.applicable_to?(object, context)
    object.class.name == 'App::Design'
  end

  def kind_for_email
    'player design'
  end

  def highlight_param_for_addons_page
    name
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end