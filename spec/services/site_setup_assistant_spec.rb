require 'fast_spec_helper'

require 'services/site_setup_assistant'

describe SiteSetupAssistant do
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:service) { described_class.new(site) }

  describe '#current_step & #current_step_number' do
    context 'current_assistant_step is "addons"' do
      before { allow(site).to receive(:current_assistant_step).and_return('addons')}

      it 'returns "addons"' do
        expect(service.current_step).to eq 'addons'
        expect(service.current_step_number).to eq 2
      end
    end

    context 'current_assistant_step is "player"' do
      before { allow(site).to receive(:current_assistant_step).and_return('player')}

      it 'returns "player"' do
        expect(service.current_step).to eq 'player'
        expect(service.current_step_number).to eq 3
      end
    end
  end

end
