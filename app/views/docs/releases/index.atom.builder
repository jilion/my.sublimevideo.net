atom_feed do |feed|
  feed.title "SublimeVideo Releases"
  feed.updated @releases.first.datetime
  feed.author do |author|
    author.name("Jilion")
    author.email("info@jilion.com")
  end

  @releases.each do |release|
    feed.entry("releases", id: release.datetime.to_i, url: "#{releases_url}##{release.datetime.strftime("%Y-%m-%d-%H-%M")}") do |entry|
      entry.title(l(release.datetime, format: :feed))
      entry.content(release.atom_content, type: 'html')
      entry.updated(release.datetime.strftime("%Y-%m-%dT%H:%M:%SZ")) # needed to work with Google Reader.
      entry.author do |author|
        author.name("Jilion")
        author.email("info@jilion.com")
      end
    end
  end
end
