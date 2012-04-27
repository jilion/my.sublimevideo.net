# coding: utf-8

module Admin::AdminHelper

  def current_utc_time
    raw "<strong>Current UTC time:</strong> #{l(Time.now.utc, format: :seconds_timezone)}"
  end

  def viped(user)
    if user.vip?
      raw "★#{yield}★"
    else
      yield
    end
  end

  def display_tags_list(tags, filter_name = :tagged_with)
    links = tags.inject([]) do |list, tag|
      list << link_to("#{tag.name} (#{display_integer(tag.count)})", url_for(filter_name => tag.name), remote: true, class: 'remote')
    end
    raw links.join(" | ")
  end

  def formatted_pluralize(count, singular, plural = nil)
    pluralize(count, singular, plural).sub(/\d+/) { |number| display_integer(number) }
  end

end
