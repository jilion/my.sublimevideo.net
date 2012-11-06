require_dependency 'service/loader'

module Service
  module App
    ComponentVersion = Struct.new(:component_version) do

      def create
        component_version.save!
        Service::Loader.delay.update_all_dependant_sites(component_version.id)
        true
      rescue ActiveRecord::RecordInvalid
        false
      end

    end
  end
end
