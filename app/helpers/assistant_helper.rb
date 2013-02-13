module AssistantHelper

  def step_class(current_step, given_step)
    classes = []

    if SiteSetupAssistant.step_number(current_step) == SiteSetupAssistant.step_number(given_step)
      classes << 'active'
    elsif SiteSetupAssistant.step_number(current_step) > SiteSetupAssistant.step_number(given_step)
      classes << 'completed'
    end
  end

end
