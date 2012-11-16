module OneTime
  module VideoTag
    class << self
      def mongo_to_pg
        skip = 410000
        while skip < 1036086
          delay(priority: 500).migrate_mongo_to_pg(skip)
          skip += 10000
        end
      end

      def migrate_mongo_to_pg(skip)
        ::VideoTag.skip(skip).limit(10000).each do |video_tag|
          NewVideoTagUpdater.delay(priority: 300).migrate(video_tag.id)
        end
      end
    end
  end
end
