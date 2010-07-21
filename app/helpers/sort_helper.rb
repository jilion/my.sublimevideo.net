module SortHelper
  
  def link_to_sort(field, url, *args)
    options = args.extract_options!
    options.reverse_merge!(:label => field.to_s.humanize, :remote => true, :reverse => false, :default => false)
    
    # If there is a current sort on the given field, the way of the sort (send to the scope in the controller) is reversed,
    # or if there is another current sort and the sort has the :reverse option, set way as 'desc' (the opposite of starting sort)
    # otherwise, set the starting way for normal sort: 'asc'
    way = ((current_way_for(field) == 'asc') || (sorted_not_by?(field) && options[:reverse])) ? 'desc' : 'asc'
    
    # The 'active' class is applied when params include a sort for the given field,
    # or if no sort is present in params but the sort has the :default options
    class_active = 'active' if currently_sorted_by?(field) || (!currently_sorted? && options[:default])
    
    # The 'up' class is applied when sort is reversed Z->A, opposite if the sort has the :reverse options
    class_up = 'up' if current_way_for(field) == (options[:reverse] ? 'asc' : 'desc')
    
    link_to("#{url}?by_#{field}=#{way}&page=#{params[:page]||1}", :class => ['sort', field, class_active, class_up].join(" "), :remote => options[:remote], :onclick => "MySublimeVideo.makeRemoteLinkSticky(this); MySublimeVideo.showTableSpinner()") do
      content_tag(:strong, content_tag(:span, options[:label], :class => 'arrow')) \
      + content_tag(:span, '', :class => 'corner')
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
  
  def sorted_not_by?(field)
    currently_sorted? && !currently_sorted_by?(field)
  end
  
end