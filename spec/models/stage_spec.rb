require 'fast_spec_helper'
require 'active_support/core_ext'

require 'models/stage'

describe Stage do
  describe ".stages" do
    it "returns all available stages" do
      expect(Stage.stages).to eq Stage::STAGES
    end
  end

  describe ".stages_equal_or_less_stable_than" do
    it "returns all stages less stable than 'stable'" do
      expect(Stage.stages_equal_or_less_stable_than('stable')).to eq %w[stable beta alpha]
    end

    it "returns all stages less stable than 'beta'" do
      expect(Stage.stages_equal_or_less_stable_than('beta')).to eq %w[beta alpha]
    end

    it "returns all stages less stable than 'alpha'" do
      expect(Stage.stages_equal_or_less_stable_than('alpha')).to eq %w[alpha]
    end
  end

  describe ".stages_equal_or_more_stable_than" do
    it "returns all stages less stable than 'stable'" do
      expect(Stage.stages_equal_or_more_stable_than('stable')).to eq %w[stable]
    end

    it "returns all stages less stable than 'beta'" do
      expect(Stage.stages_equal_or_more_stable_than('beta')).to eq %w[stable beta]
    end

    it "returns all stages less stable than 'alpha'" do
      expect(Stage.stages_equal_or_more_stable_than('alpha')).to eq %w[stable beta alpha]
    end
  end

  describe ".version_stage" do
    it "returns stable for 1.0.0" do
      expect(Stage.version_stage('1.0.0')).to eq 'stable'
    end

    it "returns beta for 1.0.0-beta.1" do
      expect(Stage.version_stage('1.0.0-beta.1')).to eq 'beta'
    end

    it "returns alpha for 1.0.0-alpha.1" do
      expect(Stage.version_stage('1.0.0-alpha.1')).to eq 'alpha'
    end
  end
end
