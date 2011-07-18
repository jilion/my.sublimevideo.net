require 'spec_helper'

describe Api do

  describe ".current_version" do
    it { subject.current_version.should be == 1 }
  end

  describe ".default_content_type" do
    it { subject.default_content_type.should be == 'json' }
  end

end
