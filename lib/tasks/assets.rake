pt = Rake::Task['assets:environment']
Rake.application.send(:eval, "@tasks.delete('assets:environment')")

namespace :assets do
  task :environment do
    module ::Mongoid
      def load!(config_file)
        puts "Skipping connection to Mongo DB"
      end
    end

    pt.execute
  end
end
