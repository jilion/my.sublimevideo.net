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
    its(:poster_url)      { should eq 'http://media.jilion.com/vcg/ms_800.jpg' }
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
    it { should validate_presence_of(:uid) }
    it { should validate_presence_of(:uid_origin) }
    # it { should validate_uniqueness_of(:site_id).scoped_to(:uid) } # doesn't work with null: false on uid
    it { should ensure_inclusion_of(:name_origin).in_array(%w[attribute source]) }
    it { should ensure_inclusion_of(:uid_origin).in_array(%w[attribute source]) }
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
            url: 'http://media.jilion.com/vcg/ms_240p.mp4',
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
            url: 'http://media.jilion.com/vcg/ms_240p.mp4',
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

  describe "#data" do
    let(:video_tag) { described_class.new }

    %w[
      uid uid_origin
      name name_origin
      video_id video_id_origin
      poster_url
      duration
      size
      current_sources sources
      settings
    ].each do |attribute|
      it "includes #{attribute}" do
        video_tag.data.keys.should include(attribute)
      end
    end

    %w[id created_at updated_at].each do |attribute|
      it "doesn't include #{attribute}" do
        video_tag.data.keys.should_not include(attribute)
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
#  size            :string(255)
#  sources         :text
#  uid             :string(255)      not null
#  uid_origin      :string(255)      not null
#  updated_at      :datetime         not null
#  video_id        :string(255)
#  video_id_origin :string(255)
#
# Indexes
#
#  index_video_tags_on_site_id_and_uid         (site_id,uid) UNIQUE
#  index_video_tags_on_site_id_and_updated_at  (site_id,updated_at)
#

