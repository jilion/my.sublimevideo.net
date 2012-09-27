module OneTime
  module Site

    class << self

      def regenerate_templates(options = {})
        scheduled, delay = 0, 5
        ::Site.active.find_each(batch_size: 100) do |site|
          if options[:loaders]
            Player::Loader.delay(priority: 200, run_at: delay.seconds.from_now).update_all_modes!(site.id, touch: false, purge: false)
          end
          if options[:settings]
            Player::Settings.delay(priority: 200, run_at: delay.seconds.from_now).update_all_types!(site.id, touch: false, purge: false)
          end

          scheduled += 1

          if (scheduled % 500).zero?
            puts "#{scheduled} sites scheduled..."
            delay += 5
          end
        end

        "Finished: in total, #{scheduled} sites will have their loader and license re-generated"
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
