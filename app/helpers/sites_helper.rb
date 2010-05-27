module SitesHelper
  
  def sublime_video_script_tag_for(site)
    "<script type=\"text/javascript\" src=\"http://cdn.sublimevideo.net/js/#{site.token}.js\"></script>"
  end
  
end