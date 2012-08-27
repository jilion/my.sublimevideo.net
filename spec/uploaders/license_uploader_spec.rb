require 'spec_helper'

describe LicenseUploader do
  let(:license) { fixture_file('license.js') }

  before do
    described_class.enable_processing = true
    @uploader = described_class.new(create(:site), :file)
  end

  after do
    described_class.enable_processing = false
    @uploader.remove!
  end

  context 'content-type' do
    before { @uploader.store!(license) }

    context "javascript file" do
      it "content-type is set to text/javascript" do
        @uploader.file.content_type.should eq "text/javascript"
      end
    end

    context "gziped javascript file" do
      it "content-type is set to text/javascript" do
        @uploader.file.content_type.should eq "text/javascript"
      end
    end
  end
end
