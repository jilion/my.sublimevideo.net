module EarlyAccessControllerHelper
  LIST = %w[]

  def self.list
    LIST
  end

  def early_access?(feature)
    current_user_early_access.include?(feature)
  end

  def early_access_body_class
    current_user_early_access.map do |feature|
      feature.empty? ? nil : "early_access_#{feature}"
    end.compact.join(' ')
  end

  def self.included(base)
    if base.respond_to?(:helper_method)
      base.send :helper_method, :early_access_body_class
      base.send :helper_method, :early_access?
    end
  end

  def current_user_early_access
    if !Rails.env.production? && params[:early_access]
      [params[:early_access]]
    else
      current_user.try(:early_access) || []
    end
  end

end
