load File.dirname(__FILE__) + '/assets.rake'

desc "Heroku deploy"
task :deploy => 'assets:prepare' do
  %x(git commit -am 'Updated assets before deploy')
  %x(git push heroku)
end