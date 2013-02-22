require 'fast_spec_helper'
require 'configurator'

require 'models/sublime_video_api'

describe SublimeVideoApi do

  describe ".current_version" do
    it { described_class.current_version.should eq(1) }
  end

  describe ".default_content_type" do
    it { described_class.default_content_type.should eq('json') }
  end

end