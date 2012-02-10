# coding: utf-8
require 'spec_helper'

feature "encode-videos-for-the-web" do
  it "should contain text" do
    go 'docs', 'encode-videos-for-the-web'

    current_url.should eq "http://docs.sublimevideo.dev/encode-videos-for-the-web"
    # first line
    page.should have_content("A <video> element can link to multiple video files encoded in different formats")
    # last line
    page.should have_content("especially if you’re uploading Ogg and WebM videos.")
  end
end

feature "faq" do
  it "should contain text" do
    go 'docs', 'faq'

    current_url.should eq "http://docs.sublimevideo.dev/faq"
  end
end

feature "javascript-api" do
  it "should contain text" do
    go 'docs', 'javascript-api'

    current_url.should eq "http://docs.sublimevideo.dev/javascript-api/usage"
    # title
    page.should have_content("Using the JavaScript API")
    page.should have_content("API Object")
    page.should have_content("API Methods")
  end
end

feature "put-video-in-a-floating-lightbox" do
  it "should contain text" do
    go 'docs', 'put-video-in-a-floating-lightbox'

    current_url.should eq "http://docs.sublimevideo.dev/put-video-in-a-floating-lightbox"
    # 1st paragraph: first line
    page.should have_content("SublimeVideo comes with integrated zooming capabilities to load and display videos in a floating “lightbox”.")
    # 1st paragraph: last line
    page.should have_content("Here is the HTML code needed to obtain the lightbox effect:")
    # code: first line
    page.should have_content('<a class="sublime" href="http://yoursite.com/video-mobile.mp4">')
    # code: last line
    page.should have_content('</video>')
    # 2nd paragraph: first line
    page.should have_content("The first 3 lines represent the “clickable thumbnail”:")
    # 2nd paragraph: last line
    page.should have_content("It needs the zoom class (in addition to the sublime class)")
  end
end

feature "quickstart-guide" do
  it "should contain text" do
    go 'docs', 'quickstart-guide'

    current_url.should eq "http://docs.sublimevideo.dev/quickstart-guide"
    # 1st paragraph: first line
    page.should have_content("Step 1: Add your site")
    # 1st paragraph: last line
    page.should have_content("the “sublime” class and take care of the rest. Here is how your <video> element should look:")
    # code: first line
    page.should have_content('<video class="sublime" width="640" height="360" poster="video-poster.jpg" preload="none">')
    # code: second line
    page.should have_content('</video>')
    # 2nd paragraph: one single line
    page.should have_content("Please read how to write proper <video> elements to learn more about this.")
  end
end

feature "supported-browsers-and-platforms" do
  it "should contain text" do
    go 'docs', 'supported-browsers-and-platforms'

    current_url.should eq "http://docs.sublimevideo.dev/supported-browsers-and-platforms"
    # first line
    page.should have_css("table#supported_browsers")
    # last line
    page.should have_content("any iPhone model can be freely upgraded to OS 3")
  end
end

feature "troubleshooting" do
  it "should contain text" do
    go 'docs', 'troubleshooting'

    current_url.should eq "http://docs.sublimevideo.dev/troubleshooting"
    # 1st paragraph: first line
    page.should have_content("Videos don’t start playing")
    # 1st paragraph: last line
    page.should have_content("Read more about H.264 video encoding.")
  end
end

feature "releases" do
  it "should be accessible" do
    go 'docs', 'releases'

    current_url.should eq "http://docs.sublimevideo.dev/releases"
  end
end

feature "write-proper-video-elements" do
  it "should contain text" do
    go 'docs', 'write-proper-video-elements'

    current_url.should eq "http://docs.sublimevideo.dev/write-proper-video-elements"
    # 1st paragraph: first line
    page.should have_content("The <video> tag is the core element used to embed videos in HTML5.")
    # 1st paragraph: last line
    page.should have_content("Here is how your <video> element should look:")
    # code: first line
    page.should have_content('<video class="sublime"')
    # code: last line
    page.should have_content('</video>')
    # 2nd paragraph: last line
    page.should have_content("For more information about the HTML5 <video> element, please read the W3C specification.")
  end
end