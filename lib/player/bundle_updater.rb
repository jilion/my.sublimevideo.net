module Player::BundleUpdater

  def self.update(bundle, attributes)
    if bundle.name == 'app' # loader update needed
      bundle.attributes = attributes
      if bundle.valid? && bundle.changed?
        diff = bundle.version_tags.diff(bundle.version_tags_was)
        diff.each do |tag, version|
          Player::Loader.delay.update!(tag, version)
        end
        bundle.save
      end
    else
      bundle.update_attributes(attributes)
    end
  end

end
