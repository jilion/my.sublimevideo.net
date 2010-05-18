module ApplicationHelper
  
  # If text is longer than +length+, text will be middle-truncated to the length of +:length+ (defaults to 30)
  # and the last characters will be replaced with the +:omission+ (defaults to "…").
  def truncate_middle(text, *args)
    options = args.extract_options!
    options.reverse_merge!(:length => 30, :omission => "...")
    
    if text
      if(sl=text.mb_chars.length <= options[:length])
        text
      else
        tl = options[:omission].mb_chars.length
        hl = (options[:length]-tl)/2
        text[0..hl] + options[:omission] + text[-hl..-1]
      end
    end
  end
  
end