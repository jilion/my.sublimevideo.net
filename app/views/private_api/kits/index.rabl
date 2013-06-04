collection @kits

attributes :identifier, :name, :settings, :created_at, :updated_at

child(:design) { attributes :name }
