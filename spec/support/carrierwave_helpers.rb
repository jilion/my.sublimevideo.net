module Spec
  module Support
    module CarrierWaveHelpers

      def with_carrierwave_fog_configuration
        CarrierWave.fog_configuration
        yield
        CarrierWave.file_configuration
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::CarrierWaveHelpers)
