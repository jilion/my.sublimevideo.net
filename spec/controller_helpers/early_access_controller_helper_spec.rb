require 'fast_spec_helper'

require 'controller_helpers/early_access_controller_helper'

describe EarlyAccessControllerHelper do

  class Controller
    extend EarlyAccessControllerHelper
  end

  describe "current_user_early_access" do
    let(:current_user) { double('user', early_access: ['video']) }
    before { Controller.stub(:current_user) { current_user } }

    context "in dev mode" do
      before { Rails.stub_chain(:env, :production?) { false } }
      after { Rails.stub_chain(:env, :production?) { true } }

      it "overwrites current_user_early_access with params[:early_access]" do
        current_user.stub(:early_access) { ['video'] }
        Controller.stub(:params) { { early_access: 'custom_player' } }
        Controller.current_user_early_access.should eq ['custom_player']
      end

      it "returns current_user_early_access if params[:early_access] is nil" do
        current_user.should_receive(:try).with(:early_access) { ['video'] }
        Controller.stub(:params) { {} }
        Controller.current_user_early_access.should eq ['video']
      end
    end

    context "not in dev mode" do
      before { Rails.stub_chain(:env, :production?) { true } }

      it "returns current_user_early_access" do
        current_user.should_receive(:try).with(:early_access) { ['video'] }
        Controller.current_user_early_access.should eq ['video']
      end
    end
  end

  describe "early_access?" do
    it "returns true if current_user have access to early feature" do
      Controller.stub(:current_user_early_access) { ['video'] }
      Controller.early_access?('video').should be_true
    end

    it "returns false if current_user doesn't have access to early feature" do
      Controller.stub(:current_user_early_access) { [] }
      Controller.early_access?('videos').should be_false
    end
  end

  describe "early_access_body_class" do
    it "add 'early_access' to each feature access" do
      Controller.stub(:current_user_early_access) { ['video', 'custom_player'] }
      Controller.early_access_body_class.should eq('early_access_video early_access_custom_player')
    end
  end

end
