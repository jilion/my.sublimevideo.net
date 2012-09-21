require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')

require File.expand_path('lib/s3')
require File.expand_path('app/models/player')
require File.expand_path('app/models/player/loader')

describe Player::Loader, :fog_mock do
  let(:site) { mock("Site",
    token: 'abcd1234',
    player_mode: 'beta'
  )}

  context "on stable mode" do
    let(:loader) { Player::Loader.new(site, 'stable') }

    describe "initialize" do
      it "generates properly the loader file from templates" do
        loader.file.should be_present
      end
    end

    describe "upload!" do
      before { CDN.stub(:purge) }

      describe "uploaded loader file on each destination" do
        before { loader.upload! }

        context "on sublimevideo bucket" do
          let(:bucket) { S3.buckets['sublimevideo'] }
          let(:path)   { "js/#{site.token}.js" }

          it "is public" do
            object_acl = S3.fog_connection.get_object_acl(bucket, path).body
            object_acl['AccessControlList'].should include(
              {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
            )
          end
          it "have good content_type public" do
            object_headers = S3.fog_connection.get_object(bucket, path).headers
            object_headers['Content-Type'].should eq 'text/javascript'
          end
          it "have 5 min max-age cache control" do
            object_headers = S3.fog_connection.get_object(bucket, path).headers
            object_headers['Cache-Control'].should eq 'max-age=120, public'
          end
          it "includes good loader version" do
            object = S3.fog_connection.get_object(bucket, path)
            object.body.should include '/p/beta/sublime.js'
          end
        end

        context "on loaders bucket" do
          let(:bucket) { S3.buckets['loaders'] }
          let(:path)   { "loaders/#{site.token}.js" }

          it "is public" do
            object_acl = S3.fog_connection.get_object_acl(bucket, path).body
            object_acl['AccessControlList'].should include(
              {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
            )
          end
          it "have good content_type public" do
            object_headers = S3.fog_connection.get_object(bucket, path).headers
            object_headers['Content-Type'].should eq 'text/javascript'
          end
          it "have 5 min max-age cache control" do
            object_headers = S3.fog_connection.get_object(bucket, path).headers
            object_headers['Cache-Control'].should eq 'max-age=120, public'
          end
          it "includes good player mode path" do
            object = S3.fog_connection.get_object(bucket, path)
            object.body.should include '/p/beta/sublime.js'
          end
        end
      end

      it "purges loader file from CDN" do
        CDN.should_receive(:purge).with("/js/#{site.token}.js")
        loader.upload!
      end
    end

    describe "#delete!" do
      before do
        CDN.stub(:purge)
        loader.upload!
      end

      context "on sublimevideo bucket" do
        let(:bucket) { S3.buckets['sublimevideo'] }
        let(:path)   { "js/#{site.token}.js" }

        it "deletes settings file" do
          loader.delete!
          expect { S3.fog_connection.get_object(bucket, path) }.to raise_error(Excon::Errors::NotFound)
        end

        it "purges loader file from CDN" do
          CDN.should_receive(:purge).with("/js/#{site.token}.js")
          loader.delete!
        end
      end

      context "on loaders bucket" do
        let(:bucket) { S3.buckets['loaders'] }
        let(:path)   { "loaders/#{site.token}.js" }

        it "deletes settings file" do
          loader.delete!
          expect { S3.fog_connection.get_object(bucket, path) }.to raise_error(Excon::Errors::NotFound)
        end

        it "purges loader file from CDN" do
          CDN.should_receive(:purge).with("/js/#{site.token}.js")
          loader.delete!
        end
      end
    end

  end

  context "on beta (& alpha) mode" do
    let(:loader) { Player::Loader.new(site, 'beta') }
    let(:bucket) { S3.buckets['sublimevideo'] }
    let(:path)   { "js/#{site.token}-beta.js" }

    describe "initialize" do
      it "generates properly the loader file from templates" do
        loader.file.should be_present
      end
    end

    describe "upload!" do
      before { CDN.stub(:purge) }

      describe "uploaded loader file on each destination" do
        before { loader.upload! }

        it "is public" do
          object_acl = S3.fog_connection.get_object_acl(bucket, path).body
          object_acl['AccessControlList'].should include(
            {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
          )
        end
        it "have good content_type public" do
          object_headers = S3.fog_connection.get_object(bucket, path).headers
          object_headers['Content-Type'].should eq 'text/javascript'
        end
        it "have 5 min max-age cache control" do
          object_headers = S3.fog_connection.get_object(bucket, path).headers
          object_headers['Cache-Control'].should eq 'max-age=120, public'
        end
        it "includes components path" do
          object = S3.fog_connection.get_object(bucket, path)
          object.body.should include '[]'
        end
      end

      it "purges loader file from CDN" do
        CDN.should_receive(:purge).with("/#{path}")
        loader.upload!
      end
    end

    describe "#delete!" do
      before do
        CDN.stub(:purge)
        loader.upload!
      end

      it "deletes settings file" do
        loader.delete!
        expect { S3.fog_connection.get_object(bucket, path) }.to raise_error(Excon::Errors::NotFound)
      end

      it "purges loader file from CDN" do
        CDN.should_receive(:purge).with("/#{path}")
        loader.delete!
      end
    end
  end

end
