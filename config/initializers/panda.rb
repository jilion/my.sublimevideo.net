panda_config = YAML::load_file(Rails.root.join('config', 'panda.yml'))
Panda.connect!(panda_config)