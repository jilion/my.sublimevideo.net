Panda.connect!(YAML::load_file(File.join(File.dirname(__FILE__), '..', 'panda.yml'))[Rails.env])