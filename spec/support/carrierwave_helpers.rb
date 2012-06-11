module Spec
  module Support
    module CarrierWaveHelpers
      
      # TODO Improve that (maybe with Fog.mock!) to avoid real internet connection.
      def with_carrierwave_fog_configuration
        CarrierWave.fog_configuration
        yield
        CarrierWave.file_configuration
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::CarrierWaveHelpers)
