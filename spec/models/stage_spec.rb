require 'fast_spec_helper'
require 'active_support/core_ext'

require 'models/stage'

describe Stage do
  describe ".stages" do
    it "returns all available stages" do
      Stage.stages.should eq Stage::STAGES
    end
  end

  describe ".stages_with_access_to" do
    it "returns all stages with access to 'alpha'" do
      Stage.stages_with_access_to('stable').should eq %w[stable beta alpha]
    end

    it "returns all stages with access to 'beta'" do
      Stage.stages_with_access_to('beta').should eq %w[beta alpha]
    end

    it "returns all stages with access to 'alpha'" do
      Stage.stages_with_access_to('alpha').should eq %w[alpha]
    end
  end

  describe ".version_stage" do
    it "returns stable for 1.0.0" do
      Stage.version_stage('1.0.0').should eq 'stable'
    end

    it "returns beta for 1.0.0-beta.1" do
      Stage.version_stage('1.0.0-beta.1').should eq 'beta'
    end

    it "returns alpha for 1.0.0-alpha.1" do
      Stage.version_stage('1.0.0-alpha.1').should eq 'alpha'
    end
  end
end
