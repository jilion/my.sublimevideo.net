module OneTime
  module Site

    class << self

      def regenerate_templates(options)
        total, delay = 0, 5
        ::Site.active.find_each(batch_size: 100) do |site|
          ::Site.delay(priority: 200, run_at: delay.seconds.from_now).update_loader_and_license(site.id, options)
          total += 1

          if (total % 100).zero?
            puts "#{total} sites scheduled..."
            delay += 5
          end
        end

        "Finished: in total, #{total} sites will have their loader and license re-generated"
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
