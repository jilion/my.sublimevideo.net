require 'spec_helper'

describe KitsController do

  verb_and_actions = { get: [:show, :edit], put: :update }
  it_behaves_like 'redirect when connected as', 'http://my.test.host/suspended', [[:user, { state: 'suspended' }]], verb_and_actions, site_id: '1'
  it_behaves_like 'redirect when connected as', 'http://my.test.host/login', [:guest], verb_and_actions, site_id: '1'

  context 'logged-in' do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user) }
    before do
      sign_in user
      allow_any_instance_of(described_class).to receive(:_gracefully_find_kit).and_return(double('Kit'))
      allow_any_instance_of(described_class).to receive(:_upload_custom_logo)
    end

    it_behaves_like 'responds to formats', [:js], :get, [:fields, :process_custom_logo] do
      let(:params) { { site_id: site.token, id: '1', kit: { settings: {} } } }
    end
  end

end
