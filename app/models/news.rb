class News

  attr_accessor :title, :url, :categories, :date

  def initialize(entry)
    @title      = entry.title
    @url        = entry.links.first
    @categories = entry.categories
    @date       = entry.published
  end

  def self.get_latest_sublimevideo_news(count)
    feed = Feedzirra::Feed.fetch_and_parse("http://blog.jilion.com/atom.xml")
    news = feed.entries.select { |entry| entry.categories.include?('sublimevideo') && entry.categories.exclude?('sublimevideo-showcase') }
    news[0...count].inject([]) do |news, entry|
      news << News.new(entry)
    end
  end

end