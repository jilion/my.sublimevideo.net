require 'spec_helper'

describe Configurator do
  before do
    @conf = { 'development' => { 'bar' => 'dev_bar', 'baz' => 'dev_baz', 'bla' => false }, 'production' => { 'bar' => 'heroku_env', 'baz' => 'heroku_env', 'bla' => false } }
    ENV['FOO_BAR'] = 'prod_bar' # fake prod env config
    ENV['FOO_BAZ'] = 'prod_baz' # fake prod env config
  end

  module Foo
    include Configurator

    heroku_config_file 'foo.yml'
    heroku_config_accessor 'FOO', :bar, :baz
  end

  describe "accessors" do
    before do
      YAML.stub(:load_file) { @conf }
      Rails.stub(:env) { 'development' }
    end

    it { Foo.config_path.should eql Rails.root.join('config', 'foo.yml') }
    it { Foo.prefix.should eql 'FOO' }
    it { Foo.yml_options.should eql @conf['development'].to_options }
  end

  describe "heroku_config_accessor" do
    context "config file exists" do
      before { YAML.should_receive(:load_file).with(Foo.config_path) { @conf } }

      context "development env" do
        before do
          Foo.reset_yml_options
          Rails.should_receive(:env) { 'development' }
        end

        it { Foo.bar.should eql 'dev_bar' }
        it { Foo.baz.should eql 'dev_baz' }
        it { Foo.bla.should eql false }
      end

      context "production env" do
        before do
          Foo.reset_yml_options
          Rails.should_receive(:env) { 'production' }
        end

        it { Foo.bar.should eql 'prod_bar' }
        it { Foo.baz.should eql 'prod_baz' }
        it { Foo.bla.should eql false }
      end
    end

    context "config file not found" do
      before { Foo.reset_yml_options }

      it { expect { Foo.bar }.to raise_error(Errno::ENOENT) }
    end
  end

end
