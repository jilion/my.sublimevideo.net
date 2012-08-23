require "fast_spec_helper"
require File.expand_path('lib/configurator')

describe Configurator do

  context "with Rails Env" do
    let(:conf_with_rails_env) { {
      'development' => { 'bar' => 'dev_bar', 'baz' => { 'baz2' => 'dev_baz' }, 'bla' => false },
      'production'  => { 'bar' => 'env_var', 'baz' => { 'baz2' => 'env_var' }, 'bla' => false }
    } }
    before do
      ENV['CONFIGURABLE_MODULE_BAR'] = 'prod_bar' # fake prod env config
      ENV['CONFIGURABLE_MODULE_BAZ'] = 'prod_baz' # fake prod env config
    end

    module ConfigurableModule
      include Configurator

      config_file 'configurable_module.yml'
      config_accessor :bar, :baz
    end

    subject { ConfigurableModule }

    describe "accessors" do
      before do
        YAML.stub(:load_file) { conf_with_rails_env }
        Rails.stub(:env) { 'development' }
      end
      after { Rails.stub(:env) { 'test' } }

      its(:config_path) { should eq Rails.root.join('config', 'configurable_module.yml') }
      its(:prefix)      { should eq 'CONFIGURABLE_MODULE' }
      its(:yml_options) { should eq conf_with_rails_env['development'] }
    end

    describe "config_accessor" do
      context "config file exists" do
        before do
          ConfigurableModule.instance_variable_set(:@yml_options, nil) # avoid memoization
          YAML.stub(:load_file).with(ConfigurableModule.config_path) { conf_with_rails_env }
        end
        after { Rails.stub(:env) { 'test' } }

        context "development env" do
          before { Rails.stub(:env) { 'development' } }

          its(:bar) { should eq 'dev_bar' }
          its(:baz) { should eq('baz2' => 'dev_baz') }
          its(:bla) { should eq false }

          describe "hash access" do
            it "is available via sym or string" do
              subject.baz[:baz2].should eq subject.baz['baz2']
            end
          end
        end

        context "production env" do
          before { Rails.stub(:env) { 'production' } }

          its(:bar) { should eq 'prod_bar' }
          its(:baz) { should eq('baz2' => 'env_var') }
          its(:bla) { should eq false }

          describe "hash access" do
            it "is available via sym or string" do
              subject.baz[:baz2].should eq subject.baz['baz2']
            end
          end
        end
      end

      context "config file not found" do
        it { expect { subject.bar }.to raise_error(Errno::ENOENT) }
      end
    end
  end

  context "without Rails.env" do
    let(:conf_without_rails_env) { { 'a' => 1 } }
    before { YAML.stub(:load_file) { conf_without_rails_env } }

    module ConfigurableWithoutRailsEnvModule
      include Configurator
      config_file 'configurable_without_rails_env_module.yml', rails_env: false
    end

    subject { ConfigurableWithoutRailsEnvModule }

    its(:a) { should eq 1 }
  end

end
