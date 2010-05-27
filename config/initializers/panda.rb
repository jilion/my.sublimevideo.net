panda_config = YAML::load_file(Rails.root.join('config', 'panda.yml'))[Rails.env]
Panda.connect!(panda_config)