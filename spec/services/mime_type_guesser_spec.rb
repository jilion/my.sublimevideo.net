require 'fast_spec_helper'

require 'services/mime_type_guesser'

describe MimeTypeGuesser do

  describe ".guess" do
    context "asset is found" do
      before { described_class.stub(:head).and_return('content-type' => 'video/mp4') }

      it "returns the Content-Type header" do
        MimeTypeGuesser.guess("http://foo.com/bar.mp4").should eq 'video/mp4'
      end
    end

    context "asset is not found" do
      before { described_class.stub(:head).and_return({ 'content-type' => 'invalid' }) }

      it "returns an empty string" do
        MimeTypeGuesser.guess("http://foo.com/bar.mp4").should eq 'invalid'
      end
    end
  end

end
