require 'fast_spec_helper'

require 'services/file_header_analyzer'

describe FileHeaderAnalyzer do

  describe ".content_type" do
    it "returns content-type to text/javascript for .js files" do
      expect(FileHeaderAnalyzer.new('foo.js').content_type).to eq 'text/javascript'
    end

    it "returns content-type to text/javascript for .jgz files" do
      expect(FileHeaderAnalyzer.new('foo.jgz').content_type).to eq 'text/javascript'
    end

    it "returns automatically guessed content-type for other files" do
      expect(FileHeaderAnalyzer.new('foo.jpg').content_type).to eq 'image/jpeg'
      expect(FileHeaderAnalyzer.new('foo.txt').content_type).to eq 'text/plain'
    end

    it "returns empty string for unguessable content-type" do
      expect(FileHeaderAnalyzer.new('.DS_Store').content_type).to eq ""
    end
  end

end
