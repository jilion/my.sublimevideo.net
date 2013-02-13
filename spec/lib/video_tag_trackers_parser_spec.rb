require 'fast_spec_helper'
require 'active_support/core_ext'
require 'addressable/uri'

require 'services/notifier'
require File.expand_path('lib/video_tag_trackers_parser')

describe VideoTagTrackersParser do

  before {
    Notifier.stub(:send)
  }

  it "extracts video_tag meta_data from only extra & main domain" do
    video_tags_trackers = {
      "?t=site1234&e=l&d=d&h=e&vu[]=video123&pz[]=300x400" => 1,
      "?t=site1234&e=l&d=d&h=m&vu[]=video124&pz[]=300x400" => 1,
      "?t=site1234&e=l&d=d&h=i&vu[]=video125&pz[]=300x400" => 1,
      "?t=site1234&e=l&d=d&h=d&vu[]=video126&pz[]=300x400" => 1
    }
    described_class.extract_video_tags_data(video_tags_trackers).should eql({
      ['site1234', 'video123'] => { 'z' => '300x400' },
      ['site1234', 'video124'] => { 'z' => '300x400' }
    })
  end

  context "load event" do
    context "with 1 video" do
      let(:video_tags_trackers) { {
        "?t=site1234&e=l&d=d&h=m&vu[]=video123&pz[]=300x400" => 1,
        "?t=site1234&e=l&d=d&h=m&vu[]=video123&pz[]=300x400" => 1
      }}

      it "extracts one video tag meta_data" do
        described_class.extract_video_tags_data(video_tags_trackers).should eql({
          ['site1234', 'video123'] => { 'z' => '300x400' }
        })
      end
    end

    context "with 2 videos" do
      let(:video_tags_trackers) { {
        "?t=site1234&e=l&d=d&h=m&vu[]=video123&vu[]=video345&pz[]=300x400&pz[]=480x360" => 1,
        "?t=site1234&e=l&d=d&h=m&vu[]=video123&pz[]=300x400" => 1
      }}

      it "extracts two video tag meta_data" do
        described_class.extract_video_tags_data(video_tags_trackers).should eql({
          ['site1234', 'video123'] => { 'z' => '300x400' },
          ['site1234', 'video345'] => { 'z' => '480x360' }
        })
      end
    end

    context "with empty vu info" do
      let(:video_tags_trackers) { {
        "?t=2xrynuh2&e=l&du=http%3A%2F%2Fwww.schooltube.com%2Fvideo%2F1995bd32d3dc3e000a9d%2FDubstep&dt=Dubstep&ru=http%3A%2F%2Fwww.schooltube.com%2Fsearch%2F%3Fterm%3DDeadmau5&sr=768x1024&bl=en-us&pt[]=i&pm[]=h&pff[]=&pz[]=620x350&vu[]" => 1
      }}

      it "extracts 0 video tag meta_data" do
        described_class.extract_video_tags_data(video_tags_trackers).should eql({})
      end
    end
  end

  context "view event" do
    context "with 1 video" do
      let(:video_tags_trackers) { {
        "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source12.mp4&vc=source12&vcs[]=source12&vcs[]=source34&vsq=hd&vsf=mp4&vsr=1280x720" => 1,
        "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source34.webm&vc=source34&vcs[]=source12&vcs[]=source34&vsq=base&vsf=webm&vsr=460x340" => 1
      } }

      it "extracts one video tag meta_data" do
        described_class.extract_video_tags_data(video_tags_trackers).should eql({
          ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
            'd' => nil,
            'cs' => ['source12', 'source34'],
            's'  => {
              'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
              'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
            }
          }
        })
      end
    end

    context "with 1 youtube video" do
      let(:video_tags_trackers) { {
        "?t=site1234&e=s&d=d&h=m&vu=youtube123&vuo=y&vi=youtube123&vio=y&vd=1231" => 1,
        "?t=site1234&e=s&d=d&h=m&vu=youtube123&vuo=y&vi=youtube123&vio=y&vd=1231" => 1
      } }

      it "extracts one video tag meta_data" do
        described_class.extract_video_tags_data(video_tags_trackers).should eq({
          ['site1234', 'youtube123'] => { 'uo' => 'y',
            'i' => 'youtube123', 'io' => 'y',
            'd'  => 1231,
            'cs' => []
          }
        })
      end
    end

    context "with 1 video and changes" do
      let(:video_tags_trackers) { {
        "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source12.mp4&vc=source12&vcs[]=source12&vcs[]=source34&vsq=hd&vsf=mp4&vsr=1280x720&vp=http%3A//posters.sublimevideo.net/video123.png" => 1,
        "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source34.webm&vc=source34&vcs[]=source12&vcs[]=source34&vsq=base&vsf=webm&vsr=460x340&vp=http%3A//posters.sublimevideo.net/video123.png" => 1,
        "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20New%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source35.webm&vc=source35&vcs[]=source12&vcs[]=source35&vsq=base&vsf=webm&vsr=480x360&vp=http%3A//posters.sublimevideo.net/video1235.png" => 1
      } }

      it "extracts one video tag meta_data" do
        described_class.extract_video_tags_data(video_tags_trackers).should eql({
          ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My New Video', 'no' => 's',
            'd' => nil,
            'p'  => 'http://posters.sublimevideo.net/video1235.png',
            'cs' => ['source12', 'source35'],
            's'  => {
              'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
              'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' },
              'source35' => { 'u' => 'http://videos.sublimevideo.net/source35.webm', 'q' => 'base', 'f' => 'webm', 'r' => '480x360' }
            }
          }
        })
      end
    end

    context "with 2 video and changes" do
      let(:video_tags_trackers) { {
        "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source12.mp4&vc=source12&vcs[]=source12&vcs[]=source34&vsq=hd&vsf=mp4&vsr=1280x720&vp=http%3A//posters.sublimevideo.net/video123.png" => 1,
        "?t=site5678&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source45.webm&vc=source45&vcs[]=source44&vcs[]=source45&vsq=hd&vsf=webm&vsr=1280x720&vp=http%3A//posters.sublimevideo.net/video123.png" => 1
      } }

      it "extracts two video tag meta_data" do
        described_class.extract_video_tags_data(video_tags_trackers).should eql({
          ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
            'd' => nil,
            'p'  => 'http://posters.sublimevideo.net/video123.png',
            'cs' => ['source12', 'source34'],
            's'  => {
              'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
            }
          },
          ['site5678', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
            'd' => nil,
            'p'  => 'http://posters.sublimevideo.net/video123.png',
            'cs' => ['source44', 'source45'],
            's'  => {
              'source45' => { 'u' => 'http://videos.sublimevideo.net/source45.webm', 'q' => 'hd', 'f' => 'webm', 'r' => '1280x720' },
            }
          }
        })
      end
    end
  end

end
