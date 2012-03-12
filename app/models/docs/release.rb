class Docs::Release
  extend ActiveModel::Naming

  attr_accessor :datetime, :content

  def initialize(attrs)
    @datetime, @content = attrs[:datetime], attrs[:content]
  end

  def self.all(path = Rails.root.join('app/views/docs/releases'))
    path.entries.inject([]) do |releases, file_path|
      Rails.logger.info file_path.to_s
      if matches = file_path.to_s.match(/([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2})\.textile/)
        releases << new(
          datetime: DateTime.parse(matches[0]),
          content: RedCloth.new(File.new(path.join(file_path)).read).to_html.html_safe
        )
      end
      releases
    end.sort_by { |r| r.datetime }
  end

  def atom_content
    content.to_str.split("\n").each do |line|
      line.sub!(%r{<span\s+class="label\s+[a-z]+">([a-z]+)</span>}) { "[#{$1.try(:upcase)}]" }
    end.join("\n")
  end

end
