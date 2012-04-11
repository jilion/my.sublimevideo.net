require 'spec_helper'

describe Configurator do
  before do
    @conf = { 'development' => { 'bar' => 'dev_bar', 'baz' => 'dev_baz', 'bla' => false }, 'production' => { 'bar' => 'heroku_env', 'baz' => 'heroku_env', 'bla' => false } }
    ENV['CONFIGURABLE_MODULE_BAR'] = 'prod_bar' # fake prod env config
    ENV['CONFIGURABLE_MODULE_BAZ'] = 'prod_baz' # fake prod env config
  end

  module ConfigurableModule
    include Configurator

    heroku_config_file 'configurable_module.yml'
    heroku_config_accessor 'CONFIGURABLE_MODULE', :bar, :baz
  end

  subject { ConfigurableModule }

  describe "accessors" do
    before do
      YAML.stub(:load_file) { @conf }
      Rails.stub(:env) { 'development' }
    end

    its(:config_path) { should eq Rails.root.join('config', 'configurable_module.yml') }
    its(:prefix)      { should eq 'CONFIGURABLE_MODULE' }
    its(:yml_options) { should eq @conf['development'].symbolize_keys }
  end

  describe "heroku_config_accessor" do
    context "config file exists" do
      before { YAML.should_receive(:load_file).with(ConfigurableModule.config_path) { @conf } }

      context "development env" do
        before do
          ConfigurableModule.reset_yml_options
          Rails.should_receive(:env) { 'development' }
        end

        its(:bar) { should eq 'dev_bar' }
        its(:baz) { should eq 'dev_baz' }
        its(:bla) { should eq false }
      end

      context "production env" do
        before do
          ConfigurableModule.reset_yml_options
          Rails.should_receive(:env) { 'production' }
        end

        its(:bar) { should eq 'prod_bar' }
        its(:baz) { should eq 'prod_baz' }
        its(:bla) { should eq false }
      end
    end

    context "config file not found" do
      before { ConfigurableModule.reset_yml_options }

      it { expect { subject.bar }.to raise_error(Errno::ENOENT) }
    end
  end

end
