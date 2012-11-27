require_dependency 'service/loader'

module Service
  module App
    ComponentVersion = Struct.new(:component_version) do

      def create
        component_version.save!
        Service::Loader.delay.update_all_dependant_sites(component_version.component_id, component_version.stage)
        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def destroy
        # component_version.remove_zip!
        component_version.destroy
        Service::Loader.delay.update_all_dependant_sites(component_version.component_id, component_version.stage)
        true
      end

    end
  end
end
