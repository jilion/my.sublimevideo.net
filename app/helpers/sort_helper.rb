module SortHelper
  
  def sort_hash(field, *args)
    options = args.extract_options!
    options.reverse_merge!(:reverse => false)
    
    sort_by = :"by_#{field}"
    way = ((params[sort_by].nil? && options[:reverse]) || (params[sort_by].present? && params[sort_by] == 'asc')) ? 'desc' : 'asc'
    { sort_by => way, :page => params[:page] }
  end
  
  def sort_classes(field, *args)
    options = args.extract_options!
    options.reverse_merge!(:default => false, :reverse => false)
    
    sort_by = :"by_#{field}"
    active = " active" if params[sort_by].present? || (options[:default] && params.keys.select { |k| k =~ %r(^by_\w+$) }.all? { |s| s.to_sym == sort_by })
    way = " up" if params[sort_by] == (options[:reverse] ? 'asc' : 'desc')
    
    "sort #{field}#{active}#{way}"
  end
  
end