require 'fast_spec_helper'

require 'controller_helpers/early_access_controller_helper'

describe EarlyAccessControllerHelper do

  class Controller
    extend EarlyAccessControllerHelper
  end

  describe "current_user_early_access" do
    let(:current_user) { double('user', early_access: ['video']) }
    before { allow(Controller).to receive(:current_user) { current_user } }

    context "in dev mode" do
      before { Rails.stub_chain(:env, :production?) { false } }
      after { Rails.stub_chain(:env, :production?) { true } }

      it "overwrites current_user_early_access with params[:early_access]" do
        allow(current_user).to receive(:early_access) { ['video'] }
        allow(Controller).to receive(:params) { { early_access: 'custom_player' } }
        expect(Controller.current_user_early_access).to eq ['custom_player']
      end

      it "returns current_user_early_access if params[:early_access] is nil" do
        expect(current_user).to receive(:try).with(:early_access) { ['video'] }
        allow(Controller).to receive(:params) { {} }
        expect(Controller.current_user_early_access).to eq ['video']
      end
    end

    context "not in dev mode" do
      before { Rails.stub_chain(:env, :production?) { true } }

      it "returns current_user_early_access" do
        expect(current_user).to receive(:try).with(:early_access) { ['video'] }
        expect(Controller.current_user_early_access).to eq ['video']
      end
    end
  end

  describe "early_access?" do
    it "returns true if current_user have access to early feature" do
      allow(Controller).to receive(:current_user_early_access) { ['video'] }
      expect(Controller.early_access?('video')).to be_truthy
    end

    it "returns false if current_user doesn't have access to early feature" do
      allow(Controller).to receive(:current_user_early_access) { [] }
      expect(Controller.early_access?('videos')).to be_falsey
    end
  end

  describe "early_access_body_class" do
    it "add 'early_access' to each feature access" do
      allow(Controller).to receive(:current_user_early_access) { ['video', 'custom_player'] }
      expect(Controller.early_access_body_class).to eq('early_access_video early_access_custom_player')
    end
  end

end
