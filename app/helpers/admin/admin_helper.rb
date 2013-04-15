# coding: utf-8

module Admin::AdminHelper

  def current_utc_time
    raw "<strong>Current UTC time:</strong> #{l(Time.now.utc, format: :seconds_timezone)}"
  end

  def distance_of_time_in_words_to_now(from_time, include_seconds = false)
    if from_time > Time.now.utc.to_date
      "#{super} from now"
    else
      "#{super} ago"
    end
  end

  def viped(user)
    if user.vip?
      raw "★#{yield}★"
    else
      yield
    end
  end

  def display_tags_list(tags, filter_name = :tagged_with)
    links = tags.reduce([]) do |a, e|
      a << link_to("#{e.name} (#{display_integer(e.count)})", url_for(filter_name => e.name), remote: true, class: 'remote')
    end
    raw links.join(' | ')
  end

  def formatted_pluralize(count, singular, plural = nil)
    pluralize(count, singular, plural).sub(/\d+/) { |number| display_integer(number) }
  end

  def viped(user)
    if user.vip?
      raw "★#{yield}★"
    else
      yield
    end
  end

end
