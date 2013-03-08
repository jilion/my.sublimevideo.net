module App
  class ComponentVersionManager
    attr_reader :component_version

    def initialize(component_version)
      @component_version = component_version
    end

    def create
      component_version.save!
      if component_version.name == 'app'
        component_version.component.clear_caches # force cache clearance
        LoaderGenerator.delay(queue: 'high').update_all_dependant_sites(component_version.component_id, component_version.stage)
        CampfireWrapper.delay.post("#{campfire_message} released")
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def destroy
      component_version.destroy
      LoaderGenerator.delay(queue: 'high').update_all_dependant_sites(component_version.component_id, component_version.stage)
      CampfireWrapper.delay.post("#{campfire_message} DELETED!")
      true
    end

  private

    def campfire_message
      "#{component_version.name.humanize} player component version #{component_version.version}"
    end

  end
end
