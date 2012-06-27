module OneTime
  module Site

    class << self

      def regenerate_templates(options)
        scheduled, delay = 0, 5
        ::Site.active.find_each(batch_size: 100) do |site|
          ::Site.delay(priority: 200, run_at: delay.seconds.from_now).update_loader_and_license(site.id, options)
          scheduled += 1

          if (scheduled % 500).zero?
            puts "#{scheduled} sites scheduled..."
            delay += 5
          end
        end

        "Finished: in total, #{scheduled} sites will have their loader and license re-generated"
      end

      def set_first_billable_plays_at
        processed, updated = 0, 0
        ::Site.not_archived.where(first_billable_plays_at: nil).find_each(batch_size: 500) do |site|
          if stat = Stat::Site::Day.last_stats(token: site.token, fill_missing_days: false).detect { |s| s.billable_vv >= 10 }
            site.update_column(:first_billable_plays_at, stat.d)
            updated += 1
          end
          processed += 1
          print "."

          puts "\n#{processed} sites processed..." if (processed % 5000).zero?
          puts "\n#{updated} sites updated..." if updated > 0 && (updated % 100).zero?
        end

        "Finished: #{processed} sites processed and #{updated} sites updated..."
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
