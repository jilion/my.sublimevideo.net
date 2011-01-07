module TextHelper

  # If text is longer than +options[:length]+ (defaults to 30), text will be middle-truncated
  # and the last characters will be replaced with the +options[:omission]+ (defaults to "...").
  def truncate_middle_reusing_rails_truncate(text, *args)
    options = args.extract_options!
    options.reverse_merge!(:length => 30, :omission => "...")

    if text
      if text.mb_chars.length <= options[:length]
        text
      else
        side_length        = options[:length]/2
        options[:omission] = options[:omission] + text[-side_length, side_length]
        truncate(text, options)
      end
    end
  end

  # If text is longer than +options[:length]+ (defaults to 30), text will be middle-truncated
  # and the last characters will be replaced with the +options[:omission]+ (defaults to "...").
  def truncate_middle(text, *args)
    options = args.extract_options!
    options.reverse_merge!(:length => 30, :omission => "...")

    if text
      if text.mb_chars.length <= options[:length]
        text
      else
        side_length = (options[:length]-options[:omission].mb_chars.length)/2
        text[0..side_length] + options[:omission] + text[-side_length..-1]
      end
    end
  end

end
