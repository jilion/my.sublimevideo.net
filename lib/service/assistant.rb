module Service
  Assistant = Struct.new(:site) do

    self::STEPS = %w[new_site addons player publish_video summary]

    def setup_done?
      site.billable_views.nonzero? || current_step == 'summary'
    end

    def current_step
      site.current_assistant_step || 'addons'
    end

    def current_step_number
      self.class::STEPS.index(current_step) + 1
    end

  end
end
