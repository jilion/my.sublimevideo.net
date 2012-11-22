module OneTime
  module VideoTag

    class << self

      def update_names
        scheduled = 0
        ::VideoTag.select(:id).where(sources_origin: [nil, 'youtube', 'vimeo']).find_each(batch_size: 100) do |video_tag|
          ::VideoTagUpdater.delay(queue: 'low').update_name(video_tag.id)

          scheduled += 1
          if (scheduled % 1000).zero?
            puts "#{scheduled} video_tag scheduled..."
          end
        end

        "Schedule finished: #{scheduled} video_tags will have their name updated"
      end

    end

  end
end
