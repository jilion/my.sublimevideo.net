require 'spec_helper'
require 'carrierwave/test/matchers'

describe LoaderUploader do
  include CarrierWave::Test::Matchers

  before do
    described_class.enable_processing = true
    @uploader = described_class.new(create(:site), :file)
  end

  after do
    described_class.enable_processing = false
    @uploader.remove!
  end

  context 'content-type' do
    context "javascript file" do
      before { @uploader.store!(File.open(Rails.root.join('spec', 'fixtures', 'license.js'))) }

      it "content-type is set to text/javascript" do
        @uploader.file.content_type.should eq "text/javascript"
      end
    end

    context "gziped javascript file" do
      before { @uploader.store!(File.open(Rails.root.join('spec', 'fixtures', 'license.jgz'))) }

      it "content-type is set to text/javascript" do
        @uploader.file.content_type.should eq "text/javascript"
      end
    end
  end
end
