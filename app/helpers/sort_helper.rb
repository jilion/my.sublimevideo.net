module SortHelper

  def link_to_sort(field, *args)
    options = args.extract_options!
    options.reverse_merge!(:label => field.to_s.humanize, :remote => true, :default_way => 'asc', :reverse => false, :default => false)

    active = currently_sorted_by?(field) || (!currently_sorted? && options[:default])

    # If there is a current sort on the given field, the way of the sort (send to the scope in the controller) is reversed,
    # or if there is another current sort and the sort has the :reverse option, set way as 'desc' (the opposite of starting sort)
    # otherwise, set the starting way for normal sort: 'asc'
    way = active ? inverse_of_current_way(field, options[:default_way]) : options[:default_way]

    # The 'active' class is applied when params include a sort for the given field,
    # or if no sort is present in params but the sort has the :default options
    class_active = 'active' if active

    # The 'up' class is applied when sort is reversed Z->A, opposite if the sort has the :reverse options
    class_up = 'up' if active ? (way == (options[:reverse] ? 'asc' : 'desc')) : (options[:default_way] == (options[:reverse] ? 'desc' : 'asc'))

    url_params = params.reject { |k, v| k =~ /by_.*/ }
    link_to(url_for(url_params.merge("by_#{field}" => way)),
              :class => ['sort', field, class_active, class_up].join(" "),
              :remote => options[:remote],
              :onclick => "MySublimeVideo.remoteSortLink(this);") do
      content_tag(:span, options[:label], :class => 'arrow', :title => options[:title])
    end
  end

private

  def currently_sorted?
    params.keys.any?{ |k| k =~ /^by_\w+$/ }
  end

  def current_way_for(field)
    params["by_#{field}"]
  end

  def currently_sorted_by?(field)
    current_way_for(field).present?
  end

  def inverse_of_current_way(field, default_way)
    (current_way_for(field) || default_way) == 'desc' ? 'asc' : 'desc'
  end

  def not_sorted_by?(field)
    currently_sorted? && !currently_sorted_by?(field)
  end

end
