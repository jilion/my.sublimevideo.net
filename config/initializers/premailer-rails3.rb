PremailerRails.config = {
  adapter:           :hpricot,
  warn_level:        Premailer::Warnings::SAFE,
  css_to_attributes: true,
  remove_ids:        true,
  remove_classes:    true,
  remove_comments:   true,
  verbose:           Rails.env.development?
}
