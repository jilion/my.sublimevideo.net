require 'fast_spec_helper'
require 'active_support/core_ext'
require File.expand_path('lib/stage')

describe Stage do
  describe "#version_stage" do
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
