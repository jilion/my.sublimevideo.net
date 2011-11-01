require 'spec_helper'

describe VideoTag do

  describe ".video_tags_from_trackers" do

    context "with 1 video" do
      before(:each) do
        described_class.stub(:only_video_tags_trackers).and_return({
          "?t=ovjigy83&e=s&d=d&h=m&vu=abcd1234&vuo=u&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source12.mp4&vc=source12&vcs[]=source12&vcs[]=source34&vsq=hd&vsf=mp4&vsr=1280x720&vp=http%3A//posters.sublimevideo.net/abcd1234.png" => 1,
          "?t=ovjigy83&e=s&d=d&h=m&vu=abcd1234&vuo=u&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source34.webm&vc=source34&vcs[]=source12&vcs[]=source34&vsq=base&vsf=webm&vsr=460x340&vp=http%3A//posters.sublimevideo.net/abcd1234.png" => 1
        })
      end

      # specify { described_class.video_tags_from_trackers(nil).should eql({
      #   ['ovjigy83', 'abcd1234'] => { uo: 'u', vn: 'My Video', vno: 's',
      #     p: 'http://posters.sublimevideo.net/abcd1234.png',
      #     cs: ['source12', 'source34'],
      #     s: {
      #       'source12' => { u: 'http://videos.sublimevideo.net/source12.mp4', q: 'hd', r: '1280x720', f: 'mp4' },
      #       'source34' => { u: 'http://videos.sublimevideo.net/source34.webm', q: 'base', r: '460x340', f: 'webm' },
      #     }
      #   }
      # })}
    end

  end

end
