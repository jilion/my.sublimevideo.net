require 'fast_spec_helper'
# require 'rails/railtie'

require File.expand_path('app/models/app')
require File.expand_path('lib/app/mangler')

describe App::Mangler do

  describe ".mangle" do
    it "mangles hash symbol key" do
      App::Mangler.mangle(plugins: 'foo').should eq({
        "ka" => "foo"
      })
    end

    it "mangles hash string key" do
      App::Mangler.mangle('flashForced' => 'foo').should eq({
        "ta" => "foo"
      })
    end

    it "only mangles key present in the dictionary" do
      App::Mangler.mangle('flashForced' => 'foo', bar: 'foo2').should eq({
        "ta" => "foo",
        "bar" => "foo2"
      })
    end

    it "mangles recursively all keys" do
      App::Mangler.mangle('flashForced' => { enable: 'foo' }).should eq({
        "ta" => { "tm" => "foo" }
      })
    end
  end

end
