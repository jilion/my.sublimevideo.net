module NewsHelper
  
  def cached_latest_sublimevideo_news(count)
    Rails.cache.fetch("sublimevideo_news_from_blog_#{count}", expires_in: 1.hour) do
      News.get_latest_sublimevideo_news(count)
    end
  end
  
end