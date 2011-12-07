require 'spec_helper'

describe LogsFileFormat::Voxcast do

  describe "Class Methods" do
    subject { LogsFileFormat::VoxcastSites }

    describe "token? and token_from" do
      ["p/sublime.swf?t=6vibplhv","/p/close_button.png?t=6vibplhv", "/p/ie/transparent_pixel.gif?t=6vibplhv", "/p/beta/sublime.js?t=6vibplhv&super=top", '/6vibplhv/posterframe.jpg', '/js/6vibplhv/posterframe.js', '/js/6vibplhv.js', '/l/6vibplhv.js'].each do |path|
        it "returns token_from #{path}" do
          subject.token_from(path: path).should == "6vibplhv"
        end
        it "#{path} is a token" do
          subject.token?(path: path).should be_true
        end
      end

      ['/p/ie/transparent_pixel.gif HTTP/1.1', "/sublime.js?t=6vibp", "/sublime_css.js?t=6vibplhv21"].each do |path|
        it "doesn't return token_from #{path}" do
          subject.token_from(path: path).should be_nil
        end
        it "#{path} isn't a player token" do
          subject.token?(path: path).should be_false
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

  end

end
