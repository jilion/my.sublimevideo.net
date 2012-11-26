module Service
  Assistant = Struct.new(:site) do

    self::STEPS = %w[new_site addons player publish_video summary]

    def self.step_number(step_name)
      self::STEPS.index(step_name) + 1
    end

    def setup_done?
      site.views.nonzero? || current_step == 'summary'
    end

    def current_step
      site.current_assistant_step || 'addons'
    end

    def current_step_number
      self.class.step_number(current_step)
    end

  end
end
