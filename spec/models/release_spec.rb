require 'spec_helper'

describe Release do
  let(:archived_release) { create(:release).tap { |r| r.archive } }
  let(:dev_release)      { create(:release) }
  let(:beta_release)     { create(:release).tap { |r| r.flag } }
  let(:stable_release)   { create(:release).tap { |r| 2.times { r.flag } } }

  before { CDN.stub(:purge) }

  context "Factory" do
    use_vcr_cassette "release/dev"
    subject { dev_release }

    its(:date) { should =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}$/ }
    its(:zip)  { should be_present }

    it { should be_dev }
    it { should be_valid }
  end

  describe "Validations" do
    it { should validate_presence_of(:zip) }

    it "only allows zip file" do
      release = build(:release, zip: fixture_file('railscast_intro.mov'))
      release.should_not be_valid
      release.errors[:zip].should include("You are not allowed to upload \"mov\" files, allowed types: zip")
    end
  end

  context "archived release" do
    use_vcr_cassette "release/archived"
    subject { archived_release }

    it { should be_archived }
    it "isn't archivable" do
      subject.archive.should be_false
    end
    it "doesn't save the zip locally when not flagging to dev (only during the flag after_transition, see #files_in_zip)" do
      File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
    end
    it "purges /p/dev when flagged (becoming the dev release)" do
      CDN.should_receive(:purge).with('/p/dev')
      subject.flag
    end

    describe "when flagged"do
      before do
        S3.player_bucket.put("dev/foo.txt", "bar")
        subject.flag
      end

      it { should be_dev }

      it "empties dev dir" do
        keys_name = S3.keys_names(S3.player_bucket, 'prefix' => 'dev')
        keys_name.should_not include("/dev/foo.txt")
      end

      it "puts zip files inside dev dir" do
        keys_names = S3.keys_names(S3.player_bucket, 'prefix' => 'dev', remove_prefix: true)
        keys_names.sort.should eq subject.files_in_zip.map { |f| "/#{f}" }.sort
      end

      it "puts zip files inside dev dir with public-read" do
        S3.player_bucket.keys('prefix' => 'dev').each do |key|
          all_users_grantee = key.grantees.detect { |g| g.name == "AllUsers" }
          all_users_grantee.perms.should eq ["READ"]
        end
      end

      it "puts zip files inside dev dir with good content-type & content-encoding" do
        S3.player_bucket.keys('prefix' => 'dev').each do |key|
          key.head # refresh headers
          key.headers['content-type'].should eq FileHeader.content_type(key.to_s)
          key.headers['content-encoding'].should eq FileHeader.content_encoding(key.to_s)
        end
      end
    end
  end

  context "dev release" do
    use_vcr_cassette "release/dev"
    subject { dev_release }

    it { should be_dev }

    it "is the dev release" do
      subject.should eq Release.dev_release
    end

    it "purges /p/beta when flagged (becoming the stable release)" do
      CDN.should_receive(:purge).with('/p/beta')
      subject.flag
    end

    it "copies dev files inside dev dir with good content-type & content-encoding" do
      dev_release
      S3.player_bucket.keys('prefix' => 'dev').each do |key|
        key.head # refresh headers
        key.headers['content-type'].should eq FileHeader.content_type(key.to_s)
        key.headers['content-encoding'].should eq FileHeader.content_encoding(key.to_s)
      end
    end

    describe "when flagged" do
      before do
        S3.player_bucket.put("beta/foo.txt", "bar")
        subject.flag
      end

      it { should be_beta }

      it "removes no more used files in beta dir" do
        keys_names = S3.keys_names(S3.player_bucket, 'prefix' => 'beta')
        keys_names.should_not include("/beta/foo.txt")
      end

      it "copies dev files inside beta dir" do
        keys_names = S3.keys_names(S3.player_bucket, 'prefix' => 'beta', remove_prefix: true)
        keys_names.sort.should eq subject.files_in_zip.map { |f| "/#{f}" }.sort
      end

      it "copies dev files inside beta dir with public-read" do
        S3.player_bucket.keys('prefix' => 'beta').each do |key|
          all_users_grantee = key.grantees.detect { |g| g.name == "AllUsers" }
          all_users_grantee.perms.should eq ["READ"]
        end
      end

      it "copies dev files inside beta dir with good content-type & content-encoding" do
        S3.player_bucket.keys('prefix' => 'beta').each do |key|
          key.head # refresh headers
          key.headers['content-type'].should eq FileHeader.content_type(key.to_s)
          key.headers['content-encoding'].should eq FileHeader.content_encoding(key.to_s)
        end
      end

    end

    describe "when archived" do
      before { subject.archive }

      it { should be_archived }
    end
  end

  context "beta release" do
    use_vcr_cassette "release/beta"
    subject { beta_release }

    it { should be_beta }

    it "is also the dev release when no really dev release exists" do
      subject.should eq Release.dev_release
    end

    it "is the beta release" do
      subject.should eq Release.beta_release
    end

    it "purges /p when flagged (becoming the stable release)" do
      CDN.should_receive(:purge).with('/p')
      subject.flag
    end

    describe "when flagged" do
      before do
        @stable_release = stable_release
        subject.flag
      end

      it { should be_stable }
      it "copies beta files inside stable dir" do
        keys_names = S3.player_bucket.keys('prefix' => 'stable').select { |k| k.exists? && k.to_s != 'stable/' }.map { |k| k.to_s.sub('stable', '') }
        keys_names.sort.should eq subject.files_in_zip.map { |f| "/#{f}" }.sort
      end

      it "copies beta files inside stable dir with good content-type & content-encoding" do
        S3.player_bucket.keys('prefix' => 'stable').each do |key|
          unless key.to_s == 'stable/'
            key.head # refresh headers
            key.headers['content-type'].should eq FileHeader.content_type(key.to_s)
            key.headers['content-encoding'].should eq FileHeader.content_encoding(key.to_s)
          end
        end
      end

      it "archives old stable_release" do
        @stable_release.reload.should be_archived
      end
    end
    describe "when archived" do
      before { subject.archive }

      it { should be_archived }
    end
  end

  context "stable release" do
    use_vcr_cassette "release/stable"
    subject { stable_release }

    it { should be_stable }

    it "isn't flaggable" do
      subject.flag.should be_false
    end
    it "is also the dev release when no really dev release exists" do
      subject.should eq Release.dev_release
    end
    it "is also the beta release when no really beta release existse" do
      subject.should eq Release.beta_release
    end
    it "is the stable release" do
      subject.should eq Release.stable_release
    end

    describe "when archived" do
      before { subject.archive }

      it { should be_archived }
    end
  end

  describe "Instance Methods" do
    use_vcr_cassette "release/valid"
    subject { VCR.use_cassette('release/dev') { dev_release } }

    describe "#zipfile" do
      it "saves the zip locally" do
        subject.zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
        subject.delete_zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
      end
      it "returns a Zip::Zipfile object" do
        subject.zipfile.should be_instance_of(Zip::ZipFile)
      end
    end

    describe "#files_in_zip" do
      let(:ds_store)  { mock('ds_store', file?: true, name: '.DS_Store') }
      let(:macosx)    { mock('macosx', file?: true, name: '__MACOSX') }
      let(:sublimejs) { mock('sublimejs', file?: true, name: 'sublime.js') }

      it "excludes .DS_Store and __MACOSX files" do
        subject.stub(:zipfile) { [ds_store, macosx, sublimejs] }
        subject.files_in_zip.should eq [sublimejs]
      end

      it "auto-clears the local zip file when called with a block" do
        subject.files_in_zip do |files_in_zip_array|
          File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
        end
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
      end

      it "doesn't clear the local zip file when called without block" do
        subject.files_in_zip
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
      end
    end

    describe "#delete_zipfile" do
      it "clears the local zip file" do
        subject.zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
        subject.delete_zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
      end
    end

    after(:all) do
      CDN.stub(:purge)
      subject.delete_zipfile if File.file?(Rails.root.join("tmp/#{subject.zip.filename}"))
    end
  end

end

# == Schema Information
#
# Table name: releases
#
#  created_at :datetime         not null
#  date       :string(255)
#  id         :integer          not null, primary key
#  state      :string(255)
#  token      :string(255)
#  updated_at :datetime         not null
#  zip        :string(255)
#
# Indexes
#
#  index_releases_on_state  (state)
#

