require 'fast_spec_helper'
require 'active_support/core_ext'
require File.expand_path('app/models/video_tag_modules/presenter')

class VideoTag
  include VideoTagModules::Presenter
end

describe VideoTagModules::Presenter do
  let(:video_tag) { VideoTag.new }

  describe "#poster" do
    it "return the p if no uploaded poster" do
      poster = 'http://media.jilion.com/vcg/ms_800.jpg'
      video_tag.stub(:p) { poster }
      video_tag.poster.should eq poster
    end
  end

  describe "#sources" do

    context "with complete unordered s field" do
      before {
        video_tag.stub(:cs) { %w[5ABAC533 2ABFEFDA 97230509 4E855AFF] }
        video_tag.stub(:s) { {
        '97230509' => { u: 'http://media.jilion.com/vcg/ms_360p.webm', q: 'base', f: 'webm' },
        '2ABFEFDA' => { u: 'http://media.jilion.com/vcg/ms_720p.mp4', q: 'hd', f: 'mp4' }
        } }
      }

      it "reorders sources array from cs" do
        video_tag.sources.should eq([
          { u: 'http://media.jilion.com/vcg/ms_720p.mp4', q: 'hd', f: 'mp4' },
          { u: 'http://media.jilion.com/vcg/ms_360p.webm', q: 'base', f: 'webm' }
        ])
      end
    end

  end

end
