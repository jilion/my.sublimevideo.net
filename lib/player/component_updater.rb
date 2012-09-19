module Player::ComponentUpdater

  def self.update(component, attributes)
    # if component.name == 'app' # loader update needed
    #   component.attributes = attributes
    #   if component.valid? && component.changed?
    #     diff = component.version_tags.diff(component.version_tags_was)
    #     diff.each do |tag, version|
    #       Player::Loader.delay.update!(tag, version)
    #     end
    #     component.save
    #   end
    # else
    #   component.update_attributes(attributes)
    # end
  end

end
