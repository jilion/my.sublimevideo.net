require 'spec_helper'

describe VideoTag do

  let(:meta_data) { {
    'uo' => 'a', 'n' => 'My Video', 'no' => 'a',
    'p' => 'http://posters.sublimevideo.net/video123.png',
    'cs' => ['source11'],
    's' => {
      'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'base', 'f' => 'mp4', 'r' => '460x340' },
    }
  } }
  let(:video_tag) {
    Timecop.travel(1.minute.ago) {
      @video_tag = VideoTag.create(meta_data.merge(st: 'site_token', u: 'video_uid'))
    }
    @video_tag
  }

  describe "VideoTag creation" do
    it "touch updated_at" do
      video_tag.updated_at.should be_present
    end
  end

  describe "#update_meta_data" do
    context "with same existing meta_data" do
      it "touch updated_at" do
        expect {
          video_tag.update_meta_data(meta_data)
        }.to change { video_tag.updated_at }
      end

      it "return false because nothing change" do
        video_tag.update_meta_data(meta_data).should be_false
      end
    end

    %w[uo n no p z].each do |data|
      context "with different '#{data}' meta_data" do
        let(:new_meta_data) { meta_data.merge(data => 'new_data') }

        it "touch updated_at" do
          expect {
            video_tag.update_meta_data(new_meta_data)
          }.to change { video_tag.updated_at }
        end

        it "return true" do
          video_tag.update_meta_data(new_meta_data).should be_true
        end
      end
    end

    context "with different 'cs' meta_data" do
      let(:new_meta_data) { meta_data.merge('cs' => ['source11', 'source12']) }

      it "touch updated_at" do
        expect {
          video_tag.update_meta_data(new_meta_data)
        }.to change { video_tag.updated_at }
      end

      it "return true" do
        video_tag.update_meta_data(new_meta_data).should be_true
      end
    end

    context "with different 's' meta_data" do
      let(:new_meta_data) { meta_data.merge('s' => {
        'source11' => { 'u' => 'http://videos.sublimevideo.net/source11.mp4', 'q' => 'hd', 'f' => 'mp4', 'r' => '1280x720' },
      }) }

      it "touch updated_at" do
        expect {
          video_tag.update_meta_data(new_meta_data)
        }.to change { video_tag.updated_at }
      end

      it "return true" do
        video_tag.update_meta_data(new_meta_data).should be_true
      end
    end

  end

  describe "#meta_data" do
    subject { video_tag }

    its(:meta_data) { should eq(meta_data) }
  end

end
