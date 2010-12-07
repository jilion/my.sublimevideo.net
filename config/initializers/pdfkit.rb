PDFKit.configure do |config|
  config.wkhtmltopdf = Rails.env.production? ? Rails.root.join('vendor', 'bin', 'wkhtmltopdf-amd64').to_s : `which wkhtmltopdf`.strip
end