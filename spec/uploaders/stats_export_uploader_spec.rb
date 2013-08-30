require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'
require 'zip'
require 'carrierwave'
require 'config/carrierwave'
require 'support/fixtures_helpers'

require 'uploaders/stats_export_uploader'
require 'wrappers/s3_wrapper'

describe StatsExportUploader do
  let(:stat_export) { double(
    site_hostname: 'example.com',
    from: Time.utc(2012,1,20),
    to: Time.utc(2012,4,20)
  )}
  let(:csv) { fixture_file('stats_export.csv') }
  let(:uploader) { StatsExportUploader.new(stat_export, :file) }

  before { Rails.stub(:env) { double('test', to_s: 'test', test?: true) } }
  before { uploader.store!(csv) }

  it "has stats_exports S3.bucket" do
    uploader.fog_directory.should eq S3Wrapper.buckets[:stats_exports]
  end

  it "is private" do
    uploader.fog_public.should be_false
  end

  it "has a secure url with S3 bucket path" do
    p S3Wrapper.buckets[:stats_exports]
    uploader.file.stub(:authenticated_url) { "http://#{uploader.fog_directory}.s3.amazonaws.com/path" }
    uploader.secure_url.should eq "http://s3.amazonaws.com/#{uploader.fog_directory}/path"
  end

  it "has zip content_type" do
    uploader.file.content_type.should eq 'application/zip'
  end

  it "has zip extension" do
    uploader.file.path.should match /\.csv\.zip$/
  end

  it "has good filename" do
    uploader.filename.should eq "stats_export.example.com.20120120-20120420.csv.zip"
  end

  it "zipped properly" do
    zip = Zip::File.open(uploader.file.path)
    zip.read(zip.first).should eq csv.read
  end

end
