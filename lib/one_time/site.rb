module OneTime
  module Site

    class << self

      def regenerate_templates(options = {})
        ::Site.select(:id).where(token: ::SiteToken.tokens).each do |site|
          ::Service::Loader.delay(queue: 'high').update_all_stages!(site.id) if options[:loaders]
          ::Service::Settings.delay(queue: 'high').update_all_types!(site.id) if options[:settings]
        end
        puts "Important sites scheduled..."

        scheduled = 0
        ::Site.active.select(:id).order{ last_30_days_main_video_views.desc }.find_each do |site|
          ::Service::Loader.delay(queue: 'loader').update_all_stages!(site.id) if options[:loaders]
          ::Service::Settings.delay(queue: 'low').update_all_types!(site.id) if options[:settings]

          scheduled += 1
          puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
        end

        "Schedule finished: #{scheduled} sites will have their loader and license re-generated"
      end

      def without_versioning
        was_enabled = PaperTrail.enabled?
        PaperTrail.enabled = false
        begin
          yield
        ensure
          PaperTrail.enabled = was_enabled
        end
      end

    end

  end
end
