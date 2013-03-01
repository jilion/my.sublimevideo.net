require 'fast_spec_helper'

require 'services/file_header_analyzer'

describe FileHeaderAnalyzer do

  describe ".content_type" do
    it "returns content-type to text/javascript for .js files" do
      FileHeaderAnalyzer.new('foo.js').content_type.should eq 'text/javascript'
    end

    it "returns content-type to text/javascript for .jgz files" do
      FileHeaderAnalyzer.new('foo.jgz').content_type.should eq 'text/javascript'
    end

    it "returns automatically guessed content-type for other files" do
      FileHeaderAnalyzer.new('foo.jpg').content_type.should eq 'image/jpeg'
      FileHeaderAnalyzer.new('foo.txt').content_type.should eq 'text/plain'
    end

    it "returns empty string for unguessable content-type" do
      FileHeaderAnalyzer.new('.DS_Store').content_type.should eq ""
    end
  end

end
