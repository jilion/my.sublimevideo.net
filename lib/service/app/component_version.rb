require_dependency 'service/loader'
require_dependency 'campfire_wrapper'

module Service
  module App
    ComponentVersion = Struct.new(:component_version) do

      def create
        component_version.save!
        if component_version.name == 'app'
          Service::Loader.delay(queue: 'high').update_all_dependant_sites(component_version.component_id, component_version.stage)
          CampfireWrapper.delay.post("#{campfire_message} released")
        end
        true
      rescue ::ActiveRecord::RecordInvalid
        false
      end

      def destroy
        component_version.destroy
        Service::Loader.delay(queue: 'high').update_all_dependant_sites(component_version.component_id, component_version.stage)
        CampfireWrapper.delay.post("#{campfire_message} DELETED!")
        true
      end

    private

      def campfire_message
        "#{component_version.name.humanize} player component version #{component_version.version}"
      end

    end
  end
end
