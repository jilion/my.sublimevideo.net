require 'fast_spec_helper'
require 'active_support/core_ext'

require File.expand_path('lib/app/mangler')

describe App::Mangler do

  describe ".mangle" do
    it "mangles hash symbol key" do
      App::Mangler.mangle(plugins: 'foo').should eq({
        "ka" => "foo"
      })
    end

    it "mangles hash string key" do
      App::Mangler.mangle('force_flash' => 'foo').should eq({
        "ta" => "foo"
      })
    end

    it "mangles hash string key and camelise them" do
      App::Mangler.mangle('twitter_url' => 'foo').should eq({
        "ts" => "foo"
      })
    end

    it "only mangles key present in the dictionary" do
      App::Mangler.mangle('force_flash' => 'foo', bar: 'foo2').should eq({
        "ta" => "foo",
        "bar" => "foo2"
      })
    end

    it "mangles recursively all keys" do
      App::Mangler.mangle('force_flash' => { enable: 'foo' }).should eq({
        "ta" => { "if" => "foo" }
      })
    end

    it "doesn't mangles if parent key is 'Kits'" do
      App::Mangler.mangle('force_flash' => { "kits" => { enable: 'foo' } }).should eq({
        "ta" => { "ks" => { "enable" => "foo" } }
      })
    end
  end

end
