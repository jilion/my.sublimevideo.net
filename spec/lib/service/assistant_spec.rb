require 'fast_spec_helper'

require File.expand_path('lib/service/assistant')

Site = Struct.new(:params) unless defined?(Site)

describe Service::Assistant do
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:service) { described_class.new(site) }

  describe '#current_step & #current_step_number' do
    context 'current_assistant_step is "addons"' do
      before { site.stub(current_assistant_step: 'addons')}

      it 'returns "addons"' do
        service.current_step.should eq 'addons'
        service.current_step_number.should eq 2
      end
    end

    context 'current_assistant_step is "player"' do
      before { site.stub(current_assistant_step: 'player')}

      it 'returns "player"' do
        service.current_step.should eq 'player'
        service.current_step_number.should eq 3
      end
    end
  end

end
