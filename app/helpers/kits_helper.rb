module KitsHelper

  def display_custom_logo(url)
    return if url.blank?

    matches = url.match /_(\d+)x(\d+)@/
    tag(:img, src: url, width: matches[1].to_i / 2, height: matches[2].to_i / 2)
  end
end
