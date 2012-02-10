require 'spec_helper'

describe LogsFileFormat::Voxcast do

  describe "Class Methods" do
    subject { LogsFileFormat::VoxcastSites }

    describe "token? and token_from" do
      ["/p/sublime.swf?t=6vibplhv","/p/close_button.png?t=6vibplhv", "/p/ie/transparent_pixel.gif?t=6vibplhv", "/p/beta/sublime.js?t=6vibplhv&super=top", '/6vibplhv/posterframe.jpg', '/js/6vibplhv/posterframe.js', '/js/6vibplhv.js', '/l/6vibplhv.js'].each do |path|
        it "returns token_from #{path}" do
          subject.token_from(path: path).should eq "6vibplhv"
        end
        it "#{path} is a token" do
          subject.token?(path: path).should be_true
        end
      end

      ['/p/ie/transparent_pixel.gif HTTP/1.1', "/sublime.js?t=6vibp", "/sublime_css.js?t=6vibplhv21"].each do |path|
        it "doesn't return token_from #{path}" do
          subject.token_from(path: path).should be_nil
        end
        it "#{path} isn't a token" do
          subject.token?(path: path).should be_false
        end
      end
    end

    describe "loader_token? and loader_token_from" do
      ['/js/6vibplhv.js'].each do |path|
        it "returns player_token_from #{path}" do
          subject.loader_token_from(path: path).should eq "6vibplhv"
        end
        it "#{path} is a loader token" do
          subject.loader_token?(path: path).should be_true
        end
      end

      ["/p/beta/sublime.js?t=6vibplhv&super=top", "/p/sublime.swf?t=6vibplhv","/p/close_button.png?t=6vibplhv", "/p/ie/transparent_pixel.gif?t=6vibplhv", '/p/ie/transparent_pixel.gif HTTP/1.1', "/sublime.js?t=6vibp", "/sublime_css.js?t=6vibplhv21", '/6vibplhv/posterframe.jpg', '/js/6vibplhv/posterframe.js', '/l/6vibplhv.js'].each do |path|
        it "doesn't return token_from #{path}" do
          subject.loader_token_from(path: path).should be_nil
        end
        it "#{path} isn't a loader token" do
          subject.loader_token?(path: path).should be_false
        end
      end
    end

    describe "player_token? and player_token_from" do
      ["/p/beta/sublime.js?t=6vibplhv&super=top"].each do |path|
        it "returns player_token_from #{path}" do
          subject.player_token_from(path: path).should eq "6vibplhv"
        end
        it "#{path} is a player token" do
          subject.player_token?(path: path).should be_true
        end
      end

      ["/p/sublime.swf?t=6vibplhv","/p/close_button.png?t=6vibplhv", "/p/ie/transparent_pixel.gif?t=6vibplhv", '/p/ie/transparent_pixel.gif HTTP/1.1', "/sublime.js?t=6vibp", "/sublime_css.js?t=6vibplhv21", '/6vibplhv/posterframe.jpg', '/js/6vibplhv/posterframe.js', '/js/6vibplhv.js', '/l/6vibplhv.js'].each do |path|
        it "doesn't return player_token_from #{path}" do
          subject.player_token_from(path: path).should be_nil
        end
        it "#{path} isn't a player token" do
          subject.player_token?(path: path).should be_false
        end
      end
    end

    describe "flash_token? and flash_token_from" do
      ["/p/sublime.swf?t=6vibplhv"].each do |path|
        it "returns flash_token_from #{path}" do
          subject.flash_token_from(path: path).should eq "6vibplhv"
        end
        it "#{path} is a flash token" do
          subject.flash_token?(path: path).should be_true
        end
      end

      ["/p/beta/sublime.js?t=6vibplhv&super=top","/p/close_button.png?t=6vibplhv", "/p/ie/transparent_pixel.gif?t=6vibplhv", '/p/ie/transparent_pixel.gif HTTP/1.1', "/sublime.js?t=6vibp", "/sublime_css.js?t=6vibplhv21", '/6vibplhv/posterframe.jpg', '/js/6vibplhv/posterframe.js', '/js/6vibplhv.js', '/l/6vibplhv.js'].each do |path|
        it "doesn't return flash_token_from #{path}" do
          subject.flash_token_from(path: path).should be_nil
        end
        it "#{path} isn't a flash token" do
          subject.flash_token?(path: path).should be_false
        end
      end
    end

    describe "countable_hit?" do
      it "returns true if cache_miss_reason is 1" do
        subject.countable_hit?(cache_miss_reason: 1).should be_true
      end
      it "returns false if cache_miss_reason is 3" do
        subject.countable_hit?(cache_miss_reason: 3).should be_false
      end
    end

    describe "gif_request?" do
      ["/_.gif"].each do |path_stem|
        it "#{path_stem} is a gif request" do
          subject.gif_request?({ path_stem: path_stem }).should be_true
        end
      end

      ["/foo.html"].each do |path_stem|
        it "#{path_stem} isn't a gif request" do
          subject.gif_request?({ path_stem: path_stem }).should be_false
        end
      end
    end

    describe "event_is?" do
      ["?t=ibvjcopp&i=1310389131519&h=i&e=l&vn=1", "?e=l&t=ibvjcopp&i=1310389131519&h=i&vn=1"].each do |path_query|
        it "#{path_query} represent a 'l' event" do
          subject.event_is?({ path_query: path_query }).should be_true
        end
      end

      ["?t=ibvjcopp&i=1310389131519&h=i&e=l&vn=1", "?e=l&t=ibvjcopp&i=1310389131519&h=i&vn=1"].each do |path_query|
        it "#{path_query} represent a 'l' event, not a 's' event" do
          subject.event_is?({ path_query: path_query }, 'l').should be_true
          subject.event_is?({ path_query: path_query }, 's').should be_false
        end
      end

      ["?t=ibvjcopp&i=1310389131519&h=i&e=s&vn=1", "?e=s&t=ibvjcopp&i=1310389131519&h=i&vn=1"].each do |path_query|
        it "#{path_query} represent a 's' event, not a 'l' event" do
          subject.event_is?({ path_query: path_query }, 's').should be_true
          subject.event_is?({ path_query: path_query }, 'l').should be_false
        end
      end
    end

    describe "good_token?" do
      ["?t=6vibplhv", "?t=6vibplhv&super=top", "?foo=bar&t=6vibplhv", "?foo=bar&t=6vibplhv&super=top"].each do |path_query|
        it "#{path_query} is a good token" do
          subject.good_token?(path_query: path_query).should be_true
        end
      end

      ["?t=6vibp", "?t=6vibplhv21&super=top", "?foo=bar&t=6vibp", "?foo=bar&t=6vibp&super=top"].each do |path_query|
        it "#{path_query} isn't a good token" do
          subject.good_token?(path_query: path_query).should be_false
        end
      end
    end

    describe "remove_timestamp" do
      it "returns the string without the timestamp" do
        subject.remove_timestamp(path_query: "?t=ibvjcopp&i=1310389131519&h=i&e=l&vn=1").should eq "?t=ibvjcopp&h=i&e=l&vn=1"
      end
    end

  end

end
