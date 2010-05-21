module SortHelper
  
  def link_to_sort(field, url, *args)
    options = args.extract_options!
    options.reverse_merge!(:reverse => false, :default => false)
    
    # If there is a current sort on the given field, the way of the sort (send to the scope in the controller) is reversed,
    # or if there is another current sort and the sort has the :reverse option, set way as 'desc' (the opposite of starting sort)
    # otherwise, set the starting way for normal sort: 'asc'
    way = if (current_way_for(field) == 'asc') || (options[:reverse] && explicit_sort_not?(field))
      'desc'
    else
      'asc'
    end
    
    # The 'active' class is applied when params include a sort for the given field,
    # or if no sort is present in params but the sort has the :default options
    class_active = " active" if current_sort_by?(field) || (options[:default] && !explicit_sort?)
    
    # The 'up' class is applied when sort is reversed Z->A, opposite if the sort has the :reverse options
    class_up     = " up"     if current_way_for(field) == (options[:reverse] ? 'asc' : 'desc')
    
    link_to url + "?by_#{field}=#{way}&page=#{params[:page]||1}", :class => "sort #{field}#{class_active}#{class_up}", :remote => true, :onclick => "MySublimeVideo.makeRemoteLinkSticky(this)" do
      "<strong><span class='arrow'>#{options[:label] || field.to_s.humanize}</span></strong><span class='corner' />"
    end
  end
  
private
  
  def current_sort_by?(field)
    params["by_#{field}"].present?
  end
  
  def current_way_for(field)
    params["by_#{field}"]
  end
  
  def explicit_sort?
    params.keys.select { |k| k =~ %r(^by_\w+$) }.present?
  end
  
  def explicit_sort_not?(field)
    !current_sort_by?(field) && explicit_sort?
  end
  
end