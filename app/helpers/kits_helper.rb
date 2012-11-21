module KitsHelper

  def mangled_kit_settings(kit)
    mangled_kits_settings(kit.site)[kit.identifier].to_json
  end

  def mangled_kits_settings(site)
    @mangled_kits_settings ||= App::Mangler.mangle(Service::Settings.new(site, 'settings').kits)
  end

  def display_custom_logo(url)
    return if url.blank?

    if matches = url.match(/-(\d+)x(\d+)@/)
      tag(:img, src: url, width: matches[1].to_i / 2, height: matches[2].to_i / 2)
    end
  end

end
