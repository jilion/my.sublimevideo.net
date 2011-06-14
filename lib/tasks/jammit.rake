desc "Prepare jammit assets before deploy"
task :jammit do
  system "bundle exec jammit -u https://my.sublimevideo.net -f"

  Dir.glob("public/assets/*.css").each do |file|
    buffer = File.new(file,'r').read
    buffer.gsub!(/@media all and\(/,"@media all and (")
    buffer.gsub!(/@media screen and\(/,"@media screen and (")
    buffer.gsub!(/@media print and\(/,"@media print and (")
    File.open(file,'w') {|fw| fw.write(buffer)}
  end

  system "git add public/assets/*"
  system "git commit public/assets/* -m 'Updated assets before deploy'"
end
