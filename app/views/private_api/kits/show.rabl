object @kit
cache @kit

attributes :identifier, :name, :settings, :created_at, :updated_at

node(:default) { |kit| kit.id == kit.site.default_kit_id }

child(:design) { attributes :name }
