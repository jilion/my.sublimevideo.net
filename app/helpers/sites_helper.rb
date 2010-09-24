module SitesHelper
  
  def sublimevideo_script_tag_for(site)
    %{<script type="text/javascript" src="http://cdn.sublimevideo.net/js/%s.js"></script>} % [site.token]
  end
  
  def hostname_with_path(site)
    site.path.present? ? "#{site.hostname}/#{site.path}" : site.hostname
  end
  
  # always with span here
  def hostname_with_path_and_wildcard(site, options = {})
    length = options[:truncate] || 1000
    h_trunc_length = length * 2/3
    p_trunc_length = (site.hostname.length < h_trunc_length) ? (site.hostname.length - h_trunc_length + (length * 1/3)) : (length * 1/3)
    uri = ''
    uri += "<span class='wildcard'>(*.)</span>" if site.wildcard?
    uri += site.hostname.truncate(h_trunc_length)
    uri += "<span class='path'>/#{site.path.truncate(p_trunc_length)}</span>" if site.path.present?
    uri.html_safe
  end
  
end