PremailerRails.config = {
  adapter:            :hpricot,
  generate_text_part: true,
  warn_level:         Premailer::Warnings::SAFE,
  css_to_attributes:  true,
  remove_ids:         true,
  remove_classes:     true,
  remove_comments:    true,
  verbose:            Rails.env.development?
}
