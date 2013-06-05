require 'fast_spec_helper'

require 'services/player_mangler'

describe PlayerMangler do

  describe '.mangle' do
    it "mangles hash symbol key" do
      PlayerMangler.mangle(plugins: 'foo').should eq({
        "ka" => "foo"
      })
    end

    it "mangles hash string key" do
      PlayerMangler.mangle('force_flash' => 'foo').should eq({
        "ta" => "foo"
      })
    end

    it "mangles hash string key and camelise them" do
      PlayerMangler.mangle('twitter_url' => 'foo').should eq({
        "ts" => "foo"
      })
    end

    it "only mangles key present in the dictionary" do
      PlayerMangler.mangle('force_flash' => 'foo', bar: 'foo2').should eq({
        "ta" => "foo",
        "bar" => "foo2"
      })
    end

    it "mangles recursively all keys" do
      PlayerMangler.mangle('force_flash' => { enable: 'foo' }).should eq({
        "ta" => { "iv" => "foo" }
      })
    end

    it "doesn't mangles if parent key is 'Kits'" do
      PlayerMangler.mangle('force_flash' => { "kits" => { enable: 'foo' } }).should eq({
        "ta" => { "ks" => { "enable" => "foo" } }
      })
    end
  end

  describe '#mangle_key' do
    it 'mangles key' do
      PlayerMangler.new.mangle_key(:plugins).should eq('ka')
    end
  end

end
