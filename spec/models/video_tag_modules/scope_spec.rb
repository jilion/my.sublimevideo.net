require "spec_helper"

describe VideoTagModules::Scope do

  describe "#search" do
    before {
      [
        { n: 'Cool Video',     u: 'token123' },
        { n: 'Bad Video abc',  u: 'token123456' },
        { n: 'Super fun cool', u: 'tokenabc' }
      ].each do |attr|
        VideoTag.create(attr)
      end
    }

    it "returns all video tags if query is empty" do
      VideoTag.scoped.custom_search('').should have(3).video_tags
    end

    it "returns all video tags if query is nil" do
      VideoTag.scoped.custom_search(nil).should have(3).video_tags
    end

    it "is case insensitive" do
      VideoTag.scoped.custom_search('Cool').should have(2).video_tags
    end

    it "searchs video tag by name" do
      VideoTag.scoped.custom_search('video').should have(2).video_tags
    end

    it "searchs video tag by uid" do
      VideoTag.scoped.custom_search('123').should have(2).video_tags
    end

    it "searchs video tag by uid or name" do
      VideoTag.scoped.custom_search('abc').should have(2).video_tags
    end

  end


end
