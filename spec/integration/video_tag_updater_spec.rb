require 'spec_helper'

describe VideoTagUpdater do

  describe ".update" do
    let(:video_tag) { create(:video_tag, name: nil, name_origin: nil) }

    context "a standard video update with public YouTube video" do
      use_vcr_cassette "video_tag_update/update_with_youtube"
      let(:new_data) { {
        'i' => 'DAcjV60RnRw',
        'io' => 'y'
      } }

      it "update video name from YouTube" do
        described_class.update(video_tag.site.token, video_tag.uid, new_data)
        video_tag.reload.name.should eq 'Will We Ever Run Out of New Music?'
        video_tag.reload.name_origin.should eq 'youtube'
      end
    end

    context "a standard video update with public Vimeo video" do
      use_vcr_cassette "video_tag_update/update_with_vimeo"
      let(:new_data) { {
        'n' => 'video_file_name',
        'no' => 's',
        'cs' => ['687d6ff'],
        's' => {
          '687d6ff' => { 'u' => "http://player.vimeo.com/external/35386044.sd.mp4?s=f10c9e0acaf7cb38e9a5539c6fbcb4ac" }
        }
      } }

      it "update video name from Vimeo" do
        described_class.update(video_tag.site.token, video_tag.uid, new_data)
        video_tag.reload.name.should eq 'Sony Professional - MCS-8M Switcher'
        video_tag.reload.name_origin.should eq 'vimeo'
      end
    end
  end

end
