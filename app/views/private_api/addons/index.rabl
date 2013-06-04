collection @addon_plans

attributes :name, :title, :price, :availability, :required_stage, :stable_at, :created_at, :updated_at

child(:addon) { attributes :name }
