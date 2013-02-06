require "spec_helper"

describe VideoTag do
  let(:video_tag) { create(:video_tag) }

  context "Factory" do
    subject { video_tag }

    its(:site_id)         { should be_present }
    its(:uid)             { should be_present }
    its(:uid_origin)      { should eq 'attribute' }
    its(:name)            { should be_present }
    its(:name_origin)     { should eq 'attribute' }
    its(:poster_url)      { should eq 'http://media.sublimevideo.net/vpa/ms_800.jpg' }
    its(:size)            { should eq '640x360' }
    its(:duration)        { should eq 10000 }
    its(:current_sources) { should eq %w[57fb2708 27fe0de1 2625adcf ff83f239] }
    its(:sources)         { should have(4).sources }
    its(:settings)        { should eq({ 'badged' => "true" }) }

    it { should be_valid }
  end

  describe "Associations" do
    it { should belong_to :site }
  end

  describe "Validations" do
    it { should validate_presence_of(:site_id) }
    it { should validate_presence_of(:site_token) }
    it { should validate_presence_of(:uid) }
    it { should validate_presence_of(:uid_origin) }
    # it { should validate_uniqueness_of(:site_id).scoped_to(:uid) } # doesn't work with null: false on uid
    it { should ensure_inclusion_of(:name_origin).in_array(%w[attribute source youtube vimeo]).allow_nil }
    it { should ensure_inclusion_of(:uid_origin).in_array(%w[attribute source]) }
    it { should ensure_inclusion_of(:sources_origin).in_array(%w[youtube vimeo other]).allow_nil }
  end

  describe "#to_param" do
    it "uses uid" do
      video_tag.to_param.should eq video_tag.uid
    end
  end

  describe "#name=" do
    it "truncates long name" do
      long_name = ''
      256.times.each { long_name += 'a' }
      video_tag.update_attributes(name: long_name)
      video_tag.name.size.should eq 255
    end

    it "sets to nil" do
      video_tag.update_attributes(name: nil)
      video_tag.name.should be_nil
    end
  end

  describe "#duration=" do
    it "limits max duration integer" do
      buggy_duration = 6232573214720000
      video_tag.update_attributes(duration: buggy_duration)
      video_tag.duration.should eq 2147483647
    end
  end

  describe "#used_sources" do
    let(:video_tag) { described_class.new(
      current_sources: %w[57fb2708 27fe0de1],
      sources: {
      '57fb2708' => { url: 'http://media.sublimevideo.net/vpa/ms_360p.mp4' },
      '27fe0de1' => { url: 'http://media.sublimevideo.net/vpa/ms_720p.mp4' },
      '2625adcf' => { url: 'http://media.sublimevideo.net/vpa/ms_360p.webm' },
      }
    ) }
    it "returns only sources in current_sources" do
      video_tag.used_sources.keys.should eq video_tag.current_sources
    end
  end

  describe "#update_attributes" do
    context "with new data" do
      context ":current_sources" do
        let(:new_current_sources) { %w[57fb2708 27fe0de1] }

        it "overwrites current_sources" do
          video_tag.attributes = { current_sources: new_current_sources }
          video_tag.should be_changed
          video_tag.save.should be_true
          video_tag.reload
          video_tag.current_sources.should eq new_current_sources
        end
      end

      context ":sources" do
        context "with existing source" do
          let(:modified_source) { { '57fb2708' => {
            url: 'http://media.sublimevideo.net/vpa/ms_240p.mp4',
            quality: 'base',
            family: 'mp4',
            resolution: '480x240'
          } } }

          it "modify only one source" do
            video_tag.attributes = { sources: modified_source }
            video_tag.should be_changed
            video_tag.save.should be_true
            video_tag.reload
            video_tag.sources['57fb2708'].should eq modified_source['57fb2708']
            video_tag.sources.should have(4).sources
          end
        end

        context "with new source" do
          let(:new_source) { { 'new_crc32' => {
            url: 'http://media.sublimevideo.net/vpa/ms_240p.mp4',
            quality: 'base',
            family: 'mp4',
            resolution: '480x240'
          } } }

          it "adds the new source" do
            video_tag.attributes = { sources: new_source }
            video_tag.should be_changed
            video_tag.save.should be_true
            video_tag.reload
            video_tag.sources['new_crc32'].should eq new_source['new_crc32']
            video_tag.sources.should have(5).sources
          end
        end
      end
    end

    context "with same data" do
      context ":current_sources" do
        it "overwrites current_sources" do
          video_tag.attributes = { current_sources: video_tag.current_sources }
          video_tag.should_not be_changed
        end
      end

      context ":sources" do
        it "overwrites current_sources" do
          video_tag.attributes = { sources: Hash.new(video_tag.sources.first) }
          video_tag.should_not be_changed
        end
      end
    end
  end

  describe "#backbone_data" do
    let(:video_tag) { described_class.new }

    %w[
      uid uid_origin
      name name_origin
      sources_id sources_origin
      poster_url
    ].each do |attribute|
      it "includes #{attribute}" do
        video_tag.backbone_data.keys.should include(attribute)
      end
    end

    %w[
      id created_at updated_at
      duration
      size
      current_sources sources
      settings
    ].each do |attribute|
      it "doesn't include #{attribute}" do
        video_tag.backbone_data.keys.should_not include(attribute)
      end
    end
  end

end

# == Schema Information
#
# Table name: video_tags
#
#  created_at      :datetime         not null
#  current_sources :text
#  duration        :integer
#  id              :integer          not null, primary key
#  name            :string(255)
#  name_origin     :string(255)
#  poster_url      :text
#  settings        :hstore
#  site_id         :integer          not null
#  site_token      :string(255)      not null
#  size            :string(255)
#  sources         :text
#  sources_id      :string(255)
#  sources_origin  :string(255)
#  uid             :string(255)      not null
#  uid_origin      :string(255)      not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_video_tags_on_site_id_and_uid         (site_id,uid) UNIQUE
#  index_video_tags_on_site_id_and_updated_at  (site_id,updated_at)
#

