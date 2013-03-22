# https://groups.google.com/forum/?fromgroups=#!topic/rubyonrails-security/zAAU7vGTPvI
# This monkey patch should be removed when upgrading to Rails 2.3.14
module HTML
  class WhiteListSanitizer
    self.protocol_separator = /:|(&#0*58)|(&#x70)|(&#x0*3a)|(%|&#37;)3A/i

    def contains_bad_protocols?(attr_name, value)
      uri_attributes.include?(attr_name) &&
      (value =~ /(^[^\/:]*):|(&#0*58)|(&#x70)|(&#x0*3a)|(%|&#37;)3A/i && !allowed_protocols.include?(value.split(protocol_separator).first.downcase.strip))
    end
  end
end
