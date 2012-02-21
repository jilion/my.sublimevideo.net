require 'spec_helper'

describe FileHeader do

  describe ".content_type" do
    it "returns content-type to text/javascript for .js files" do
      described_class.content_type('foo.js').should eq 'text/javascript'
    end

    it "returns content-type to text/javascript for .jgz files" do
      described_class.content_type('foo.jgz').should eq 'text/javascript'
    end

    it "returns automatically guessed content-type for other files" do
      described_class.content_type('foo.jpg').should eq 'image/jpeg'
      described_class.content_type('foo.txt').should eq 'text/plain'
    end

    it "returns nil for unguessable content-type" do
      described_class.content_type('.DS_Store').should be_nil
    end
  end

  describe ".content_encoding" do
    it "set content-encoding to text/javascript for .gz files" do
      described_class.content_encoding('foo.gz').should eq 'gzip'
    end

    it "set content-encoding to text/javascript for .jgz files" do
      described_class.content_encoding('foo.jgz').should eq 'gzip'
    end

    it "set content-encoding to nil for other files" do
      described_class.content_encoding('foo.jpg').should be_nil
      described_class.content_encoding('foo.txt').should be_nil
    end
  end

end
