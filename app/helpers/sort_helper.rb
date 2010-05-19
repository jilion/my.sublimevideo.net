module SortHelper
  
  def sort_hash(sort_by, *args)
    options = args.extract_options!
    options.reverse_merge!(:reverse => false)
    
    way = ((params[sort_by].nil? && options[:reverse]) || (params[sort_by].present? && params[sort_by] == 'asc')) ? 'desc' : 'asc'
    
    { sort_by.to_sym => way, :page => params[:page] }
  end
  
  def sort_classes(sort_by, *args)
    options = args.extract_options!
    options.reverse_merge!(:default => false, :reverse => false)
    
    sort_name = sort_by.to_s.sub('by_', '')
    active = " active" if params[sort_by].present? || (options[:default] && params.keys.select { |k| k =~ %r(^by_\w+$) }.all? { |s| s == sort_by })
    way = " up" if (params[sort_by] == (options[:reverse] ? 'asc' : 'desc'))
    
    "sort #{sort_name}#{active}#{way}"
  end
  
end