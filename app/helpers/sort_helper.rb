module SortHelper
  
  def link_to_sort(field, url, *args)
    options = args.extract_options!
    options.reverse_merge!(:reverse => false, :default => false)
    
    sort_by      = :"by_#{field}"
    way          = ((params[sort_by].nil? && options[:reverse]) || (params[sort_by].present? && params[sort_by] == 'asc')) ? 'desc' : 'asc'
    class_active = " active" if params[sort_by].present? || (options[:default] && params.keys.select { |k| k =~ %r(^by_\w+$) }.all? { |s| s.to_sym == sort_by })
    class_up     = " up" if params[sort_by] == (options[:reverse] ? 'asc' : 'desc')
    
    link_to url + "?#{sort_by}=#{way}&page=#{params[:page]||1}", :class => "sort #{field}#{class_active}#{class_up}", :remote => true, :onclick => "MySublimeVideo.makeRemoteLinkSticky(this)" do
      "<strong><span class='arrow'>#{options[:label] || field.to_s.humanize}</span></strong><span class='corner' />"
    end
  end
  
end