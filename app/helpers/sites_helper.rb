module SitesHelper
  
  def sublimevideo_script_tag_for(site)
    %{<script type="text/javascript" src="http://cdn.sublimevideo.net/js/%s.js"></script>} % [site.token]
  end
  
end