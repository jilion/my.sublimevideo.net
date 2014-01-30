require 'fast_spec_helper'

require 'services/site_setup_assistant'

describe SiteSetupAssistant do
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:service) { described_class.new(site) }

  describe '#current_step & #current_step_number' do
    context 'current_assistant_step is "addons"' do
      before { site.stub(current_assistant_step: 'addons')}

      it 'returns "addons"' do
        service.current_step.should eq 'player'
        service.current_step_number.should eq 2
      end
    end

    context 'current_assistant_step is "player"' do
      before { site.stub(current_assistant_step: 'player')}

      it 'returns "player"' do
        service.current_step.should eq 'player'
        service.current_step_number.should eq 2
      end
    end
  end

end
