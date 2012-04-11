# coding: utf-8
require 'spec_helper'

describe VideoTag do
  before { Pusher.stub(:[]) { mock('channel', trigger: nil, stats: { occupied: true }) } }

  let(:video_tag) { VideoTag.create(
    'st' => 'site1234',
    'u'  => 'video123',
    'uo' => 'a', 'n' => 'My Video', 'no' => 'a',
    'p' => 'http://posters.sublimevideo.net/video123.png',
    'cs' => ['source11'],
    's' => {
      'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' },
    }
  )}

  describe "#meta_data" do
    subject { video_tag }

    its(:meta_data) { should eql({
      'uo' => 'a', 'n' => 'My Video', 'no' => 'a',
      'p' => 'http://posters.sublimevideo.net/video123.png',
      'cs' => ['source11'],
      's' => {
        'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' },
      }
    }) }
  end

  describe "#update_with_latest_data" do

    it "doesn't change when updating with same uo attribute" do
      Pusher.should_receive(:[]).once
      video_tag.update_with_latest_data('uo' => 'a')
    end
    it "changes when updating uo attribute" do
      Pusher.should_receive(:[]).twice
      video_tag.update_with_latest_data('uo' => 's')
    end

    it "doesn't change when updating with same s attribute" do
      Pusher.should_receive(:[]).once
      video_tag.update_with_latest_data('s' => { 'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' } })
    end
    it "changes when updating s attribute" do
      Pusher.should_receive(:[]).twice
      video_tag.update_with_latest_data('s' => { 'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' } })
      video_tag.s.should eq({
        "source11" => {"u"=>"http://videos.sublimevideo.net/source11.mp4", "q"=>"base", "f"=>"mp4", "r"=>"460x340"},
        "source12" => {"u"=>"http://videos.sublimevideo.net/source12.mp4", "q"=>"base", "f"=>"mp4", "r"=>"460x340"}
      })
    end
  end

  describe "#push_new_meta_data" do

    it "push after save if channel occupided" do
      video_tag = VideoTag.new(st: 'site1234', u: 'video123', n: 'Video 123')
      mock_channel = mock('channel')
      mock_channel.should_receive(:stats).once.and_return({occupied: true})
      mock_channel.should_receive(:trigger).once.with('video_tag', u: 'video123', meta_data: video_tag.meta_data)
      Pusher.stub(:[]).with("private-site1234") { mock_channel }
      video_tag.save
    end

    it "doesn't push after save if channel isn't occupided" do
      video_tag = VideoTag.new(st: 'site1234', u: 'video123', n: 'Video 123')
      mock_channel = mock('channel')
      mock_channel.should_receive(:stats).once.and_return({occupied: false})
      mock_channel.should_not_receive(:trigger)
      Pusher.stub(:[]).with("private-site1234") { mock_channel }
      video_tag.save
    end

  end

  describe ".create_or_update_from_trackers!" do

    context "with a new video (load)" do
      before do
        described_class.stub(:video_tags_from_trackers).and_return({
          ['site1234', 'video123'] => { 'z' => '300x400' }
        })
      end

      specify { expect { described_class.create_or_update_from_trackers!(nil) }.to change(VideoTag, :count).by(1) }
      specify { expect { 2.times { described_class.create_or_update_from_trackers!(nil) } }.to change(VideoTag, :count).by(1) }

      describe "new video_tag" do
        subject do
          described_class.create_or_update_from_trackers!(nil)
          VideoTag.first
        end

        its(:z) { should eql('300x400') }
      end
    end

    context "with a new video (view)" do
      before do
        described_class.stub(:video_tags_from_trackers).and_return({
          ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
            'p'  => 'http://posters.sublimevideo.net/video123.png',
            'cs' => ['source12', 'source34'],
            's'  => {
              'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
              'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
            }
          }
        })
      end

      specify { expect { described_class.create_or_update_from_trackers!(nil) }.to change(VideoTag, :count).by(1) }
      specify { expect { 2.times { described_class.create_or_update_from_trackers!(nil) } }.to change(VideoTag, :count).by(1) }

      describe "new video_tag" do
        subject do
          described_class.create_or_update_from_trackers!(nil)
          VideoTag.first
        end

        its(:st) { should eql('site1234') }
        its(:u)  { should eql('video123') }
        its(:uo) { should eql('a') }
        its(:n)  { should eql('My Video') }
        its(:no) { should eql('s') }
        its(:p)  { should eql('http://posters.sublimevideo.net/video123.png') }
        its(:cs) { should eql(['source12', 'source34']) }
        its(:s)  { should eql({
          'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
          'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
        }) }
      end

      describe "existing video_tag (different)" do
        before do
          Timecop.travel 1.hour.ago do
            @video_tag = video_tag
          end
        end
        subject do
          described_class.create_or_update_from_trackers!(nil)
          VideoTag.first
        end

        its(:st) { should eql('site1234') }
        its(:u)  { should eql('video123') }
        its(:uo) { should eql('a') }
        its(:n)  { should eql('My Video') }
        its(:no) { should eql('s') }
        its(:p)  { should eql('http://posters.sublimevideo.net/video123.png') }
        its(:cs) { should eql(['source12', 'source34']) }
        its(:s)  { should eql({
          'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' },
          'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
          'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
        }) }
        its(:created_at) { should eql(@video_tag.created_at) }
        its(:updated_at) { should_not == @video_tag.updated_at }
      end

      describe "existing video_tag (no change)" do
        before do
          Timecop.travel 1.hour.ago do
            described_class.create_or_update_from_trackers!(nil)
            @video_tag = VideoTag.first
          end
        end
        subject do
          described_class.create_or_update_from_trackers!(nil)
          VideoTag.first
        end

        its(:st) { should eql('site1234') }
        its(:u)  { should eql('video123') }
        its(:uo) { should eql('a') }
        its(:n)  { should eql('My Video') }
        its(:no) { should eql('s') }
        its(:p)  { should eql('http://posters.sublimevideo.net/video123.png') }
        its(:cs) { should eql(['source12', 'source34']) }
        its(:s)  { should eql({
          'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
          'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
        }) }
        its(:created_at) { should eql(@video_tag.created_at) }
        its(:updated_at) { should eql(@video_tag.updated_at) }
      end
    end

  end

  describe ".video_tags_from_trackers" do

    it "parses only extra & main domain" do
      described_class.stub(:only_video_tags_trackers).and_return({
        "?t=site1234&e=l&d=d&h=e&vu[]=video123&pz[]=300x400" => 1,
        "?t=site1234&e=l&d=d&h=m&vu[]=video124&pz[]=300x400" => 1,
        "?t=site1234&e=l&d=d&h=i&vu[]=video125&pz[]=300x400" => 1,
        "?t=site1234&e=l&d=d&h=d&vu[]=video126&pz[]=300x400" => 1
      })
      described_class.video_tags_from_trackers(nil).should eql({
        ['site1234', 'video123'] => { 'z' => '300x400' },
        ['site1234', 'video124'] => { 'z' => '300x400' }
      })
    end

    context "load event" do

      context "with 1 video" do
        before do
          described_class.stub(:only_video_tags_trackers).and_return({
            "?t=site1234&e=l&d=d&h=m&vu[]=video123&pz[]=300x400" => 1,
            "?t=site1234&e=l&d=d&h=m&vu[]=video123&pz[]=300x400" => 1
          })
        end

        specify { described_class.video_tags_from_trackers(nil).should eql({
          ['site1234', 'video123'] => { 'z' => '300x400' }
        })}
      end

      context "with 2 videos" do
        before do
          described_class.stub(:only_video_tags_trackers).and_return({
            "?t=site1234&e=l&d=d&h=m&vu[]=video123&vu[]=video345&pz[]=300x400&pz[]=480x360" => 1,
            "?t=site1234&e=l&d=d&h=m&vu[]=video123&pz[]=300x400" => 1
          })
        end

        specify { described_class.video_tags_from_trackers(nil).should eql({
          ['site1234', 'video123'] => { 'z' => '300x400' },
          ['site1234', 'video345'] => { 'z' => '480x360' }
        })}
      end

    end

    context "view event" do

      context "with 1 video" do
        before do
          described_class.stub(:only_video_tags_trackers).and_return({
            "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source12.mp4&vc=source12&vcs[]=source12&vcs[]=source34&vsq=hd&vsf=mp4&vsr=1280x720" => 1,
            "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source34.webm&vc=source34&vcs[]=source12&vcs[]=source34&vsq=base&vsf=webm&vsr=460x340" => 1
          })
        end

        specify { described_class.video_tags_from_trackers(nil).should eql({
          ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
            'p'  => nil,
            'cs' => ['source12', 'source34'],
            's'  => {
              'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
              'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' }
            }
          }
        })}
      end

      context "with 1 video and changes" do
        before do
          described_class.stub(:only_video_tags_trackers).and_return({
            "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source12.mp4&vc=source12&vcs[]=source12&vcs[]=source34&vsq=hd&vsf=mp4&vsr=1280x720&vp=http%3A//posters.sublimevideo.net/video123.png" => 1,
            "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source34.webm&vc=source34&vcs[]=source12&vcs[]=source34&vsq=base&vsf=webm&vsr=460x340&vp=http%3A//posters.sublimevideo.net/video123.png" => 1,
            "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20New%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source35.webm&vc=source35&vcs[]=source12&vcs[]=source35&vsq=base&vsf=webm&vsr=480x360&vp=http%3A//posters.sublimevideo.net/video1235.png" => 1
          })
        end

        specify { described_class.video_tags_from_trackers(nil).should eql({
          ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My New Video', 'no' => 's',
            'p'  => 'http://posters.sublimevideo.net/video1235.png',
            'cs' => ['source12', 'source35'],
            's'  => {
              'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
              'source34' => { 'u' => 'http://videos.sublimevideo.net/source34.webm', 'q' => 'base', 'f' => 'webm', 'r' => '460x340' },
              'source35' => { 'u' => 'http://videos.sublimevideo.net/source35.webm', 'q' => 'base', 'f' => 'webm', 'r' => '480x360' }
            }
          }
        })}
      end

      context "with 2 video and changes" do
        before do
          described_class.stub(:only_video_tags_trackers).and_return({
            "?t=site1234&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source12.mp4&vc=source12&vcs[]=source12&vcs[]=source34&vsq=hd&vsf=mp4&vsr=1280x720&vp=http%3A//posters.sublimevideo.net/video123.png" => 1,
            "?t=site5678&e=s&d=d&h=m&vu=video123&vuo=a&vn=My%20Video&vno=s&vs=http%3A//videos.sublimevideo.net/source45.webm&vc=source45&vcs[]=source44&vcs[]=source45&vsq=hd&vsf=webm&vsr=1280x720&vp=http%3A//posters.sublimevideo.net/video123.png" => 1
          })
        end

        specify { described_class.video_tags_from_trackers(nil).should eql({
          ['site1234', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
            'p'  => 'http://posters.sublimevideo.net/video123.png',
            'cs' => ['source12', 'source34'],
            's'  => {
              'source12' => { 'u' => 'http://videos.sublimevideo.net/source12.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
            }
          },
          ['site5678', 'video123'] => { 'uo' => 'a', 'n' => 'My Video', 'no' => 's',
            'p'  => 'http://posters.sublimevideo.net/video123.png',
            'cs' => ['source44', 'source45'],
            's'  => {
              'source45' => { 'u' => 'http://videos.sublimevideo.net/source45.webm', 'q' => 'hd', 'f' => 'webm', 'r' => '1280x720' },
            }
          }
        })}
      end

    end

  end

end
