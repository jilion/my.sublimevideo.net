module AssistantHelper

  def step_class(current_step, given_step)
    classes = []

    if Service::Assistant.step_number(current_step) == Service::Assistant.step_number(given_step)
      classes << 'active'
    elsif Service::Assistant.step_number(current_step) > Service::Assistant.step_number(given_step)
      classes << 'completed'
    end
  end

end
