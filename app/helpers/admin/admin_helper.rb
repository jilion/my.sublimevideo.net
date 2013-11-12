# coding: utf-8

module Admin::AdminHelper

  def current_utc_time
    "<strong>Current UTC time:</strong> #{l(Time.now.utc, format: :seconds_timezone)}".html_safe
  end

  def distance_of_time_in_words_to_now(from_time, include_seconds_or_options = {})
    if from_time > Time.now.utc
      "#{super} from now"
    else
      "#{super} ago"
    end
  end

  def viped(user)
    if user.vip?
      "★#{yield}★".html_safe
    else
      yield
    end
  end

  def display_tags_list(tags, filter_name = :tagged_with)
    links = tags.reduce([]) do |a, e|
      a << link_to("#{e.name} (#{display_integer(e.count)})", "/docs?#{filter_name}=#{e.name}")
    end
    links.join(' | ').html_safe
  end

end
