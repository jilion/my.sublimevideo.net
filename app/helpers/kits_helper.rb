require_dependency 'preview_kit'

module KitsHelper

  def mangled_kit_settings(kit)
    mangled_kits_settings(kit.site)[kit.identifier].to_json
  end

  def mangled_kits_settings(site)
    @mangled_kits_settings ||= App::Mangler.mangle(Service::Settings.new(site, 'settings').kits)
  end

  def app_designs_for_select(site, kit)
    items = site.app_designs.order(:id).inject([]) do |memo, app_design|
      memo << [app_design.title, app_design.id, { 'data-kit-id' => PreviewKit.kit_identifer(app_design.name) }]
    end

    options_for_select(items, kit.app_design_id)
  end

  def kit_settings_expanding_handler(name)
    id = "#{name}_handler"
    classes = ['expanding_handler']
    classes << 'expanded' if params[:expand] == id

    haml_tag("h4##{id}.#{classes.join('.')}", capture_haml { yield })
  end

  def kit_settings_expendable_block(name)
    handler_id = "#{name}_handler"
    classes = ['expandable']
    classes << 'expanded' if params[:expand] == handler_id

    haml_tag("div.#{classes.join('.')}", capture_haml { yield })
  end

  def kits_for_select(site)
    items = site.kits.order(:identifier).inject([]) do |memo, kit|
      kit = exhibit(kit)
      memo << [kit.name, kit.identifier]
    end

    options_for_select(items, site.default_kit.identifier)
  end

  def display_custom_logo(url)
    return if url.blank?

    if matches = url.match(/-(\d+)x(\d+)-\d+@/)
      tag(:img, src: url, width: matches[1].to_i / 2, height: matches[2].to_i / 2)
    end
  end

end
