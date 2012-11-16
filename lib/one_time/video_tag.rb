module OneTime
  module VideoTag
    class << self
      def mongo_to_pg
        scheduled = 0
        ::VideoTag.each do |video_tag|
          NewVideoTagUpdater.delay(priority: 300).migrate(video_tag.id)
          scheduled += 1

          if (scheduled % 10000).zero?
            puts "#{scheduled} video_tags migration scheduled..."
            sleep 30
          end
        end
        "Finished: in total, #{scheduled} video_tags be migrated"
      end
    end
  end
end
