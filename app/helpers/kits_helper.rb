module KitsHelper

  def mangled_kit_settings(kit)
    mangled_kits_settings(kit.site)[kit.identifier].to_json
  end

  def mangled_kits_settings(site)
    @mangled_kits_settings ||= App::Mangler.mangle(Service::Settings.new(site, 'settings').kits)
  end

  def app_designs_for_select(site, kit)
    items = site.app_designs.order(:id).inject([]) do |memo, app_design|
      memo << [app_design.title, app_design.id, { 'data-kit-id' => PreviewKit.kit_ids[app_design.name] }]
    end

    options_for_select(items, kit.app_design_id)
  end

  def display_custom_logo(url)
    return if url.blank?

    if matches = url.match(/-(\d+)x(\d+)-\d+@/)
      tag(:img, src: url, width: matches[1].to_i / 2, height: matches[2].to_i / 2)
    end
  end

end
